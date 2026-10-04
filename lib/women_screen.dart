import 'package:flutter/material.dart';

import 'category_model.dart';
import 'category_showcase_screen.dart';

/// Dedicated screen for the "Women" banner on the Shop screen. Layout
/// lives in CategoryShowcaseScreen; this file just wires up which category
/// it shows, so Women has its own screen/class to extend later if it
/// ever needs something the other categories don't.
class WomenScreen extends StatelessWidget {
  const WomenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CategoryShowcaseScreen(category: categoryByLabel('Women'));
  }
}
