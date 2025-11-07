part of '/quran.dart';

class ToastUtils {
  void showToast(BuildContext context, String msg) {
    final snackBar = SnackBar(
      content: Text(
        msg,
        style: QuranLibrary().naskhStyle,
        textAlign: TextAlign.center,
      ),
      backgroundColor: const Color(0xFF20497D),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.fixed,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  ///Singleton factory
  static final ToastUtils _instance = ToastUtils._internal();

  factory ToastUtils() {
    return _instance;
  }

  ToastUtils._internal();
}
