import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'fit_profile_service.dart';
import 'size_guide_screen.dart';

/// Profile > My Size. The user saves their measurements here and the app
/// uses them to suggest a size on every product page.
class MySizeScreen extends StatefulWidget {
  const MySizeScreen({super.key});

  @override
  State<MySizeScreen> createState() => _MySizeScreenState();
}

class _MySizeScreenState extends State<MySizeScreen> {
  final _service = FitProfileService.instance;

  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _chest = TextEditingController();
  final _waist = TextEditingController();
  final _hip = TextEditingController();

  bool _imperial = false;
  int _fitIndex = 1;
  bool _ready = false;
  final Map<String, String> _errors = {};

  static const _fitLabels = ['Skinny', 'Regular', 'Oversized'];
  static const _fitHints = [
    'You like it snug',
    'Standard fit',
    'You like it roomy',
  ];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    await _service.load();
    if (!mounted) return;
    setState(() {
      _imperial = _service.useImperial;
      _fitIndex = _service.fitIndex;
      _height.text = _fmtLength(_service.heightCm);
      _chest.text = _fmtLength(_service.chestCm);
      _waist.text = _fmtLength(_service.waistCm);
      _hip.text = _fmtLength(_service.hipCm);
      _weight.text = _fmtWeight(_service.weightKg);
      _ready = true;
    });
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _chest.dispose();
    _waist.dispose();
    _hip.dispose();
    super.dispose();
  }

  // ── unit helpers (everything is stored in cm / kg) ──

  static const double _cmPerIn = 2.54;
  static const double _lbPerKg = 2.2046226;

  String _trim(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  String _fmtLength(double? cm) =>
      cm == null ? '' : _trim(_imperial ? cm / _cmPerIn : cm);

  String _fmtWeight(double? kg) =>
      kg == null ? '' : _trim(_imperial ? kg * _lbPerKg : kg);

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  double? _lengthToCm(TextEditingController c) {
    final v = _parse(c);
    if (v == null) return null;
    return _imperial ? v * _cmPerIn : v;
  }

  double? _weightToKg(TextEditingController c) {
    final v = _parse(c);
    if (v == null) return null;
    return _imperial ? v / _lbPerKg : v;
  }

  void _setImperial(bool value) {
    if (value == _imperial) return;
    // Read in the old unit, then rewrite the boxes in the new one.
    final h = _lengthToCm(_height);
    final c = _lengthToCm(_chest);
    final w = _lengthToCm(_waist);
    final p = _lengthToCm(_hip);
    final kg = _weightToKg(_weight);
    setState(() {
      _imperial = value;
      _height.text = _fmtLength(h);
      _chest.text = _fmtLength(c);
      _waist.text = _fmtLength(w);
      _hip.text = _fmtLength(p);
      _weight.text = _fmtWeight(kg);
      _errors.clear();
    });
  }

  // ── validation + saving ──

  // Plausible human ranges, in cm / kg.
  static const Map<String, List<double>> _limits = {
    'height': [120, 230],
    'weight': [30, 250],
    'chest': [60, 180],
    'waist': [50, 170],
    'hip': [60, 180],
  };

  String? _check(String key, TextEditingController c, double? metric) {
    if (c.text.trim().isEmpty) return null;
    if (metric == null) return 'Enter a number';
    final range = _limits[key]!;
    if (metric < range[0] || metric > range[1]) {
      return 'That doesn\'t look right';
    }
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final height = _lengthToCm(_height);
    final weight = _weightToKg(_weight);
    final chest = _lengthToCm(_chest);
    final waist = _lengthToCm(_waist);
    final hip = _lengthToCm(_hip);

    final errors = <String, String>{};
    void check(String key, TextEditingController c, double? v) {
      final e = _check(key, c, v);
      if (e != null) errors[key] = e;
    }

    check('height', _height, height);
    check('weight', _weight, weight);
    check('chest', _chest, chest);
    check('waist', _waist, waist);
    check('hip', _hip, hip);

    if (errors.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errors);
      });
      _snack('Please check the highlighted fields');
      return;
    }

    await _service.save(
      heightCm: height,
      weightKg: weight,
      chestCm: chest,
      waistCm: waist,
      hipCm: hip,
      fitIndex: _fitIndex,
      useImperial: _imperial,
    );
    if (!mounted) return;

    final rec = _service.recommend();
    _snack(rec == null
        ? 'Saved. Add your chest, waist or hip to get a recommendation'
        : 'Saved. We\'ll suggest size ${rec.size} when you shop');
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear measurements?'),
        content: const Text(
            'Your saved measurements will be removed and size suggestions will stop.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _service.clear();
    if (!mounted) return;
    setState(() {
      _height.clear();
      _weight.clear();
      _chest.clear();
      _waist.clear();
      _hip.clear();
      _fitIndex = 1;
      _errors.clear();
    });
    _snack('Measurements cleared');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
      ),
    );
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    final lengthUnit = _imperial ? 'in' : 'cm';
    final weightUnit = _imperial ? 'lb' : 'kg';

    // Live preview from whatever is typed right now (even before saving).
    final preview = FitProfileService.compute(
      heightCm: _lengthToCm(_height),
      weightKg: _weightToKg(_weight),
      chestCm: _lengthToCm(_chest),
      waistCm: _lengthToCm(_waist),
      hipCm: _lengthToCm(_hip),
      fitIndex: _fitIndex,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'My Size',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add your measurements once and we\'ll suggest the best size on every product. You can always choose a different size.',
                      style: TextStyle(
                          fontSize: 13, height: 1.5, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 18),
                    _unitToggle(),
                    const SizedBox(height: 20),
                    _field('Height', 'height', _height, lengthUnit),
                    _field('Weight', 'weight', _weight, weightUnit),
                    _field('Chest / bust', 'chest', _chest, lengthUnit),
                    _field('Waist', 'waist', _waist, lengthUnit),
                    _field('Hip', 'hip', _hip, lengthUnit),
                    const SizedBox(height: 8),
                    const Text(
                      'How do you like your clothes to fit?',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    _fitPicker(),
                    const SizedBox(height: 22),
                    _resultCard(preview),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Save measurements',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => SizeGuideSheet.show(context),
                          child: const Text(
                            'View size guide',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        if (_service.hasAnyMeasurement)
                          TextButton(
                            onPressed: _clear,
                            child: const Text(
                              'Clear measurements',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Measurements are only used to suggest a size and stay on your account.',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _unitToggle() {
    Widget chip(String label, bool imperial) {
      final selected = _imperial == imperial;
      return Expanded(
        child: GestureDetector(
          onTap: () => _setImperial(imperial),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          chip('Metric (cm, kg)', false),
          chip('Imperial (in, lb)', true),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    String key,
    TextEditingController controller,
    String unit,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        onChanged: (_) => setState(() => _errors.remove(key)),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          errorText: _errors[key],
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          labelStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _fitPicker() {
    return Row(
      children: List.generate(_fitLabels.length, (i) {
        final selected = i == _fitIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _fitIndex = i),
            child: Container(
              margin: EdgeInsets.only(right: i == _fitLabels.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: selected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? Colors.black : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _fitLabels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fitHints[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: selected ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _resultCard(SizeRecommendation? rec) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: rec == null
          ? Row(
              children: [
                Icon(Icons.straighten, color: Colors.grey[400]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enter your chest, waist or hip (or height and weight) to see your recommended size.',
                    style: TextStyle(
                        fontSize: 12.5, height: 1.4, color: Colors.grey[600]),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    rec.size,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your recommended size',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Based on your ${rec.basis}.',
                        style: TextStyle(
                            fontSize: 12, height: 1.4, color: Colors.grey[600]),
                      ),
                      if (!rec.strong) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Add chest, waist or hip for a more accurate result.',
                          style: TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
