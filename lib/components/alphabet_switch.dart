import 'package:flutter/material.dart';

class AlphabetSwitch extends StatefulWidget {
  const AlphabetSwitch({super.key, required this.onToggle});

  final Function(bool) onToggle;

  @override
  State<AlphabetSwitch> createState() => _AlphabetSwitchState();
}

class _AlphabetSwitchState extends State<AlphabetSwitch> {
  bool isArabic = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isArabic = !isArabic;
          widget.onToggle(isArabic);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: isArabic ? Colors.green : Colors.blue,
        ),
        child: Stack(alignment: Alignment.center, children: <Widget>[
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeIn,
            left: isArabic ? 50.0 : 0.0,
            right: isArabic ? 0.0 : 50.0,
            child: Container(
              key: ValueKey<bool>(isArabic),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              alignment: Alignment.center,
              child: Text(
                isArabic ? 'ئا' : 'A',
                style: const TextStyle(color: Colors.black, fontSize: 24),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
