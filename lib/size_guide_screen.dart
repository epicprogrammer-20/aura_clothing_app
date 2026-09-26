import 'package:flutter/material.dart';

class SizeGuideSheet extends StatefulWidget {
  const SizeGuideSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const SizeGuideSheet(),
    );
  }

  @override
  State<SizeGuideSheet> createState() => _SizeGuideSheetState();
}

class _SizeGuideSheetState extends State<SizeGuideSheet> {
  bool _useCm = true;
  int _fitIndex = 1; // 0 Skinny, 1 Regular, 2 Oversized
  bool _showBodyChart = false;

  static const List<String> _fitLabels = ['Skinny', 'Regular', 'Oversized'];

  static const List<List<String>> _rowsCm = [
    ['S', '170-175', '92-96', '76-80', '92-96'],
    ['M', '175-180', '96-100', '80-84', '96-100'],
    ['L', '180-185', '100-105', '84-89', '100-105'],
    ['XL', '180-185', '105-110', '89-94', '105-110'],
    ['XXL', '185-190', '110-115', '94-99', '110-115'],
  ];

  List<List<String>> get _rowsIn {
    return _rowsCm.map((row) {
      return [row[0], _cmToIn(row[1]), _cmToIn(row[2]), _cmToIn(row[3]), _cmToIn(row[4])];
    }).toList();
  }

  String _cmToIn(String cmRange) {
    final parts = cmRange.split('-');
    final a = (double.parse(parts[0]) / 2.54).round();
    final b = (double.parse(parts[1]) / 2.54).round();
    return '$a-$b';
  }

  @override
  Widget build(BuildContext context) {
    final rows = _useCm ? _rowsCm : _rowsIn;

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Size Guide',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, size: 20, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Switch to', style: TextStyle(fontSize: 13, color: Colors.black87)),
                      Row(
                        children: [
                          const Text('Type', style: TextStyle(fontSize: 13, color: Colors.black54)),
                          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
                          const SizedBox(width: 10),
                          _unitToggle(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Fit Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                ),
                const SizedBox(height: 12),
                _fitSlider(),
                const SizedBox(height: 28),
                Row(
                  children: [
                    _chartTab('Product Chart', !_showBodyChart),
                    const SizedBox(width: 20),
                    _chartTab('Body Chart', _showBodyChart),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTable(rows),
                const SizedBox(height: 16),
                Text(
                  '*Depending on your body type and dressing habits, the above sizes are for reference only.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _unitToggle() {
    return Container(
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          _unitChip('CM', _useCm),
          _unitChip('IN', !_useCm),
        ],
      ),
    );
  }

  Widget _unitChip(String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _useCm = label == 'CM'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _fitSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_fitLabels.length, (i) {
            return Text(
              _fitLabels[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: i == _fitIndex ? FontWeight.w700 : FontWeight.w400,
                color: i == _fitIndex ? Colors.black : Colors.grey.shade500,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(_fitLabels.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Expanded(child: Container(height: 2, color: Colors.grey.shade300));
            }
            final index = i ~/ 2;
            return GestureDetector(
              onTap: () => setState(() => _fitIndex = index),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _fitIndex ? Colors.black : Colors.grey.shade300,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _chartTab(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _showBodyChart = label == 'Body Chart'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? Colors.black : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          if (active) Container(height: 2, width: label.length * 7.0, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildTable(List<List<String>> rows) {
    const headers = ['Size', 'Height', 'Bust', 'Waist Size', 'Hip Size'];
    return Table(
      border: TableBorder.all(color: Colors.grey.shade200),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade50),
          children: headers
              .map((h) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Text(
              h,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
            ),
          ))
              .toList(),
        ),
        for (final row in rows)
          TableRow(
            children: row
                .map((cell) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Text(
                cell,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: cell == row[0] ? FontWeight.w700 : FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ))
                .toList(),
          ),
      ],
    );
  }
}