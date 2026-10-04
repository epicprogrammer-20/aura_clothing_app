import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'order_history_screen.dart';

class AuraLiveChatScreen extends StatefulWidget {
  final OrderModel order;

  const AuraLiveChatScreen({super.key, required this.order});

  @override
  State<AuraLiveChatScreen> createState() => _AuraLiveChatScreenState();
}

class _AuraLiveChatScreenState extends State<AuraLiveChatScreen> {
  // How long the chat can sit idle before the bot asks if everything is solved.
  static const Duration _idleTimeout = Duration(minutes: 2);

  // The "typing..." bubbles show for a random time inside this range.
  static const int _minTypingMs = 900;
  static const int _maxTypingMs = 2000;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final Random _random = Random();

  Timer? _idleTimer;
  bool _isTyping = false;
  bool _ended = false;
  int _fallbackCount = 0;

  OrderModel get order => widget.order;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text:
            "Hi! I'm here to help you with what you need 👋\n\nAsk me about order #${order.id}, delivery, returns, cancellations, sizing, or anything else.",
        fromUser: false,
      ),
    );
    _restartIdleTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ───────────────────────── Idle handling ─────────────────────────

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    if (_ended) return;
    _idleTimer = Timer(_idleTimeout, _onIdle);
  }

  void _onIdle() {
    if (!mounted || _ended || _isTyping || _hasOpenResolvePrompt) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          text: "It's been quiet for a while. Has everything been resolved?",
          fromUser: false,
          kind: _MsgKind.resolvePrompt,
        ),
      );
    });
    _scrollToBottom();
  }

  bool get _hasOpenResolvePrompt => _messages.any(
        (m) => m.kind == _MsgKind.resolvePrompt && !m.answered,
      );

  void _dismissOpenPrompts() {
    for (final m in _messages) {
      if (m.kind == _MsgKind.resolvePrompt) m.answered = true;
    }
  }

  // ───────────────────────── Sending ─────────────────────────

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isTyping || _ended) return;

    _controller.clear();
    _idleTimer?.cancel();
    setState(() {
      _dismissOpenPrompts();
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    final started = DateTime.now();
    final wantsToLeave = _looksDone(text);

    String reply = '';
    if (!wantsToLeave) {
      reply = await _getReply(text);
    }

    // Always show the typing bubbles for 1–2 seconds so it feels human.
    final target = Duration(
      milliseconds: _minTypingMs + _random.nextInt(_maxTypingMs - _minTypingMs + 1),
    );
    final elapsed = DateTime.now().difference(started);
    if (elapsed < target) {
      await Future.delayed(target - elapsed);
    }
    if (!mounted) return;

    setState(() {
      _isTyping = false;
      if (wantsToLeave) {
        _messages.add(
          _ChatMessage(
            text: 'Glad I could help! Before you go, has everything been resolved?',
            fromUser: false,
            kind: _MsgKind.resolvePrompt,
          ),
        );
      } else {
        _messages.add(_ChatMessage(text: reply, fromUser: false));
      }
    });
    _scrollToBottom();
    _restartIdleTimer();
  }

  Future<void> _answerResolved(bool resolved) async {
    if (_isTyping || _ended) return;
    _idleTimer?.cancel();

    setState(() {
      _dismissOpenPrompts();
      _messages.add(_ChatMessage(text: resolved ? 'Yes' : 'No', fromUser: true));
      _isTyping = true;
      // Hide the message bar straight away once they say yes.
      if (resolved) _ended = true;
    });
    _scrollToBottom();

    await Future.delayed(Duration(milliseconds: 800 + _random.nextInt(700)));
    if (!mounted) return;

    setState(() {
      _isTyping = false;
      if (resolved) {
        _messages.add(_ChatMessage(
          text: 'Wonderful! Thanks for chatting with AURA. Have a great day 🖤',
          fromUser: false,
        ));
        _messages.add(_ChatMessage(
          text: 'Live chat ended',
          fromUser: false,
          kind: _MsgKind.ended,
        ));
      } else {
        _messages.add(_ChatMessage(
          text:
              "Sorry about that. Tell me what's still not sorted and I'll do my best to help.",
          fromUser: false,
        ));
      }
    });
    _scrollToBottom();
    if (!resolved) _restartIdleTimer();
  }

  // ───────────────────────── Bot brain ─────────────────────────
  //
  // BACKEND HOOK: when the AURA API is ready, replace the body of this method
  // with the HTTP call and return the reply text. The typing bubbles, delay
  // and everything else in this screen will keep working unchanged.
  Future<String> _getReply(String userText) async {
    return _localReply(userText);
  }

  static String _normalise(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll(RegExp(r"[^a-z0-9' ]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const Map<String, List<String>> _intents = {
    'track': [
      'where is', 'where s', 'track', 'tracking', 'delivery', 'deliver',
      'arrive', 'arrival', 'shipped', 'shipping status', 'status',
      'when will', 'how long', 'eta', 'late', 'delayed', 'not here yet',
      'order status', 'parcel', 'package',
    ],
    'return': [
      'return', 'send back', 'give back', 'take back', 'return policy',
      "doesn't fit", 'does not fit', "didn't fit", 'too big', 'too small',
      'too tight', 'too loose', 'changed my mind', "don't like", 'dont like',
    ],
    'refund': ['refund', 'money back', 'reimburse', 'charged', 'chargeback'],
    'cancel': ['cancel', 'stop my order', "don't want it anymore", 'dont want it'],
    'issue': [
      'wrong', 'damaged', 'defective', 'broken', 'torn', 'ripped', 'stain',
      'faulty', 'missing', 'incorrect', 'not what i ordered', 'problem',
      'issue', 'complaint', 'hole', 'dirty',
    ],
    'exchange': ['exchange', 'swap', 'different size', 'change size', 'another size', 'change colour', 'change color'],
    'size': [
      'size', 'sizing', 'fit', 'measurement', 'measurements', 'small',
      'medium', 'large', 'xl', 'what size', 'size guide',
    ],
    'payment': [
      'payment', 'paid', 'pay', 'card', 'invoice', 'receipt', 'total',
      'how much', 'price', 'cost', 'billing',
    ],
    'address': [
      'address', 'change address', 'wrong address', 'deliver to', 'ship to',
      'different address',
    ],
    'details': [
      'order details', 'what did i order', 'what i ordered', 'my order',
      'item', 'colour', 'color', 'quantity', 'summary',
    ],
    'promo': ['discount', 'promo', 'coupon', 'code', 'voucher', 'sale', 'deal', 'offer'],
    'human': [
      'human', 'agent', 'real person', 'representative', 'speak to someone',
      'talk to someone', 'call me', 'phone', 'email', 'contact', 'manager',
      'supervisor',
    ],
    'frustrated': [
      'angry', 'annoyed', 'frustrated', 'useless', 'terrible', 'worst',
      'ridiculous', 'unacceptable', 'fed up', 'not helpful', 'rubbish',
    ],
    'greeting': ['hi', 'hello', 'hey', 'howdy', 'good morning', 'good afternoon', 'good evening', 'yo', 'sup'],
    'about': ['who are you', 'what are you', 'are you a bot', 'are you real', 'your name', 'are you human'],
    'howareyou': ['how are you', 'how r u', 'how are u', "how's it going", 'hows it going'],
  };

  // Scores every intent against the message and returns the best match.
  String? _detectIntent(String normalised) {
    final padded = ' $normalised ';
    String? best;
    var bestScore = 0;

    _intents.forEach((intent, keywords) {
      var score = 0;
      for (final k in keywords) {
        if (padded.contains(' $k ') || (k.length > 4 && padded.contains(k))) {
          score += k.contains(' ') ? 3 : 2;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = intent;
      }
    });
    return best;
  }

  bool _looksDone(String raw) {
    final t = _normalise(raw);
    if (t.isEmpty || raw.contains('?')) return false;
    if (t.split(' ').length > 9) return false;

    final done = RegExp(
      r"\b(thanks|thank you|thank u|thx|cheers|ty|that is all|that's all|thats all|"
      r"nothing else|no thanks|nope|all good|all sorted|sorted|i'm good|im good|"
      r"i am good|i'm done|im done|i am done|bye|goodbye|see you|see ya|"
      r"that helps|that helped|got it|that will be all|that's it|thats it|"
      r"no that's it|no thats it|that is it|appreciate it|much appreciated)\b",
    );
    if (!done.hasMatch(t)) return false;

    // "Thanks, but where is my order?" is a real question, not a goodbye.
    final intent = _detectIntent(t);
    const real = {
      'track', 'return', 'refund', 'cancel', 'issue', 'exchange', 'size',
      'payment', 'address', 'promo', 'human',
    };
    if (intent != null && real.contains(intent)) return false;
    return true;
  }

  String _localReply(String input) {
    final t = _normalise(input);
    final intent = _detectIntent(t);

    switch (intent) {
      case 'track':
        _fallbackCount = 0;
        return _trackReply();
      case 'return':
        _fallbackCount = 0;
        return _returnReply();
      case 'refund':
        _fallbackCount = 0;
        return _refundReply();
      case 'cancel':
        _fallbackCount = 0;
        return _cancelReply();
      case 'issue':
        _fallbackCount = 0;
        return _issueReply();
      case 'exchange':
        _fallbackCount = 0;
        return _exchangeReply();
      case 'size':
        _fallbackCount = 0;
        return _sizeReply();
      case 'payment':
        _fallbackCount = 0;
        return _paymentReply();
      case 'address':
        _fallbackCount = 0;
        return _addressReply();
      case 'details':
        _fallbackCount = 0;
        return _detailsReply();
      case 'promo':
        _fallbackCount = 0;
        return "For current offers, check the Deals section in the app. Promotions and discounts show up there as soon as they go live.";
      case 'human':
        _fallbackCount = 0;
        return "I understand you'd like to speak to a person. Agent handover will be available once our support system is connected. Until then, the Help Centre has our contact options, and I'm happy to keep helping here.";
      case 'frustrated':
        _fallbackCount = 0;
        return "I'm really sorry for the frustration. Let's get this sorted. Tell me what's gone wrong with order #${order.id} and I'll point you to the quickest fix.";
      case 'greeting':
        return "Hey! 👋 What can I help you with today?";
      case 'howareyou':
        return "Doing great, thanks for asking! What can I help you with?";
      case 'about':
        return "I'm AURA's live chat support. I can help with order #${order.id}, delivery, returns, cancellations, sizing and more.";
    }

    // Nothing matched. Escalate gently the second time in a row.
    _fallbackCount++;
    if (_fallbackCount >= 2) {
      return "I'm sorry, I'm still not sure what you mean. Try one of these: \"where is my order\", \"return\", \"cancel\", \"wrong or damaged item\", or \"size help\". You can also check the Help Centre.";
    }
    return "I want to make sure I get this right. Is your question about delivery, a return, a cancellation, a problem with your item, or sizing?";
  }

  // ── Reply builders (all based on the real order data) ──

  String _trackReply() {
    final o = order;
    switch (o.status) {
      case OrderStatus.cancelled:
        return "Order #${o.id} was cancelled, so it won't be shipped. ${o.statusDate}.";
      case OrderStatus.delivered:
        return "Good news, order #${o.id} has been delivered. ${o.statusDate}.\n\nIf something isn't right with it, tell me and I'll help.";
      case OrderStatus.inTransit:
        final stage = switch (o.trackingStage) {
          0 => "It's being packed and will ship soon.",
          1 => "It has shipped and is on its way to you.",
          2 => "It's out for delivery, so it should reach you very soon.",
          _ => "It's on its way.",
        };
        return "Order #${o.id} is in transit. Current step: ${o.trackingLabel}.\n\n$stage\n\n${o.statusDate}. You can also see every step on the Track Order screen.";
    }
  }

  bool get _canCancel =>
      order.status != OrderStatus.cancelled && order.trackingStage == 0;

  String _cancelReply() {
    final o = order;
    if (o.status == OrderStatus.cancelled) {
      return "Order #${o.id} is already cancelled. Nothing more to do on your side.";
    }
    if (o.status == OrderStatus.delivered) {
      return "Order #${o.id} has already been delivered, so it can't be cancelled. If you don't want it, you can request a return instead. Want me to explain how?";
    }
    if (_canCancel) {
      return "Yes, order #${o.id} is still being packed, so you can cancel it. Go back and tap \"Cancel this order\" on the previous screen.";
    }
    return "Order #${o.id} has already shipped, so it can't be cancelled any more. Once it arrives you can request a return within 72 hours of delivery.";
  }

  String _returnReply() {
    final o = order;
    if (o.status == OrderStatus.cancelled) {
      return "Order #${o.id} was cancelled, so there's nothing to return.";
    }
    if (o.status != OrderStatus.delivered) {
      return "Returns open once your order has arrived. Order #${o.id} hasn't been delivered yet (${o.trackingLabel}). After it arrives you'll have 72 hours to request a return.";
    }
    final at = o.deliveredAt;
    if (at == null) {
      return "You can request a return within 72 hours of delivery. Go back and choose \"Return this order\" on the previous screen.";
    }
    final deadline = at.add(const Duration(hours: 72));
    final now = DateTime.now();
    if (now.isAfter(deadline)) {
      return "I'm sorry, the 72-hour return window for order #${o.id} closed on ${_formatDate(deadline)}. If the item is faulty or not as described, tell me what happened and I'll point you to the right option.";
    }
    final left = deadline.difference(now);
    final timeLeft = left.inHours >= 1
        ? '${left.inHours} hour${left.inHours == 1 ? '' : 's'}'
        : '${max(left.inMinutes, 1)} minutes';
    return "You can still return order #${o.id}. Your window closes on ${_formatDate(deadline)}, which is about $timeLeft from now.\n\nGo back and choose \"Return this order\" on the previous screen to start it.";
  }

  String _refundReply() {
    final o = order;
    if (o.status == OrderStatus.cancelled) {
      return "Order #${o.id} was cancelled, so it's marked as refunded (${o.total} to ${o.paymentMethod}). If it hasn't shown up on your statement yet, give your bank a little time to process it.";
    }
    return "Refunds are issued once a cancellation or return is processed. ${o.status == OrderStatus.delivered ? 'To start one, request a return' : 'If you want to stop this order'}, and I can walk you through it. Want me to?";
  }

  String _issueReply() {
    final o = order;
    final windowNote = o.status == OrderStatus.delivered
        ? "\n\nSince it's been delivered, please report it within 72 hours of delivery using the Order Issue screen."
        : '';
    return "I'm sorry about that. Please tell me exactly what happened with your ${o.itemTitle}: is it the wrong item, wrong size, damaged, or defective? That helps me point you to the right option.$windowNote";
  }

  String _exchangeReply() {
    final o = order;
    return "The quickest way to get a different size or colour is to request a return for order #${o.id} (within 72 hours of delivery) and place a new order for the one you want. Your current item is size ${o.size}, ${o.colorName}.";
  }

  String _sizeReply() {
    final o = order;
    return "For sizing, check the Size Guide in the app to compare measurements. For reference, order #${o.id} (${o.itemTitle}) is size ${o.size}. If it doesn't fit, tell me and I'll walk you through a return.";
  }

  String _paymentReply() {
    final o = order;
    return "Order #${o.id} total: ${o.total}, paid with ${o.paymentMethod}. Payment status: ${o.paymentStatus}. You can view or download your receipt from the order details.";
  }

  String _addressReply() {
    final o = order;
    final canStillCancel = _canCancel;
    return "Order #${o.id} is going to:\n${o.shippingName}, ${o.shippingAddress}\n\n${canStillCancel ? "It hasn't shipped yet, so if that's wrong the safest fix is to cancel it and reorder with the correct address." : o.status == OrderStatus.cancelled ? 'This order was cancelled, so no delivery will happen.' : "It has already left our warehouse, so the address can't be changed now. If you're worried it won't reach you, tell me and I'll help."}";
  }

  String _detailsReply() {
    final o = order;
    return "Order #${o.id}\n• ${o.itemTitle}\n• Size ${o.size}, ${o.colorName}, qty ${o.quantity}\n• Total ${o.total}\n• Placed ${o.orderDate}";
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final suffix = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day} at $hour12:$minute $suffix';
  }

  // ───────────────────────── UI ─────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Live Chat',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 17, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Order #${order.id} · ${order.itemTitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return const _TypingBubble();
                }
                final message = _messages[index];
                if (message.kind == _MsgKind.ended) {
                  return _EndedDivider(text: message.text);
                }
                if (message.kind == _MsgKind.resolvePrompt) {
                  return _ResolvePrompt(
                    message: message,
                    enabled: !message.answered && !_ended && !_isTyping,
                    onYes: () => _answerResolved(true),
                    onNo: () => _answerResolved(false),
                  );
                }
                return _MessageBubble(message: message);
              },
            ),
          ),
          if (!_ended) ...[
            _buildSuggestions(),
            _buildComposer(),
          ] else
            const SafeArea(top: false, child: SizedBox(height: 8)),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_messages.length > 1) return const SizedBox.shrink();

    final suggestions = [
      'Where is my order?',
      'I want to return it',
      'Can I cancel?',
      'Size help',
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(suggestions[index], style: const TextStyle(fontSize: 11.5)),
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _sendMessage(suggestions[index]),
          );
        },
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => _restartIdleTimer(),
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _sendMessage(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Models & widgets ─────────────────────────

enum _MsgKind { text, resolvePrompt, ended }

class _ChatMessage {
  final String text;
  final bool fromUser;
  final _MsgKind kind;
  bool answered = false;

  _ChatMessage({
    required this.text,
    required this.fromUser,
    this.kind = _MsgKind.text,
  });
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.80),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          // User bubbles are gray now instead of black.
          color: message.fromUser ? const Color(0xFFDADADA) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.fromUser ? 16 : 4),
            bottomRight: Radius.circular(message.fromUser ? 4 : 16),
          ),
          border: message.fromUser ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

/// Bot bubble asking "Has everything been resolved?" with Yes / No buttons.
class _ResolvePrompt extends StatelessWidget {
  final _ChatMessage message;
  final bool enabled;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _ResolvePrompt({
    required this.message,
    required this.enabled,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MessageBubble(message: message),
        if (enabled)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                _choiceButton('Yes', onYes),
                const SizedBox(width: 8),
                _choiceButton('No', onNo),
              ],
            ),
          ),
      ],
    );
  }

  Widget _choiceButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade400),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}

class _EndedDivider extends StatelessWidget {
  final String text;

  const _EndedDivider({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}

/// Three bouncing dots, shown while the bot is "thinking".
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                // Each dot is offset in time so they bounce in a wave.
                final phase = (_anim.value - i * 0.18) % 1.0;
                final bounce = sin(phase * 2 * pi).clamp(0.0, 1.0).toDouble();
                return Container(
                  width: 7,
                  height: 7,
                  margin: EdgeInsets.only(right: i == 2 ? 0 : 5, bottom: bounce * 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(Colors.grey.shade400, Colors.grey.shade700, bounce),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
