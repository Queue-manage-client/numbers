class PasswordValidator {
  static const int minLength = 10;
  static const String hint =
      '10文字以上、英大文字・英小文字・数字を含めてください';

  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードを入力してください';
    }
    if (value.length < minLength) {
      return 'パスワードは$minLength文字以上で入力してください';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return '英小文字を含めてください';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return '英大文字を含めてください';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return '数字を含めてください';
    }
    return null;
  }
}
