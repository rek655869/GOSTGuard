import 'package:flutter/material.dart';

import '../../common/widgets/base_screen.dart';

class GostsScreen extends StatefulWidget {
  const GostsScreen({super.key});

  @override
  State<GostsScreen> createState() => _GostsScreenState();
}

class _GostsScreenState extends State<GostsScreen> {

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseScreen(
      child: Text('ГОСТы'),
    );
  }
}
