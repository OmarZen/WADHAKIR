import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return QuranLibraryScreen(
      parentContext: context,
      // You can customize the appearance here
      // For example:
      // startPage: 1,
      // enableMultiSelect: true,
      // withPageView: true,
    );
  }
}
