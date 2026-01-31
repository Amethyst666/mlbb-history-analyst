import 'package:flutter/services.dart';

class DurationInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    
    // 1. Оставляем только цифры
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 2. Ограничиваем длину 4 символами (ММСС)
    if (newText.length > 4) {
      newText = newText.substring(0, 4);
    }

    // 3. Форматируем
    String formattedText = newText;
    if (newText.length >= 3) {
      // Если введено 3 или 4 цифры, ставим двоеточие после второй
      formattedText = '${newText.substring(0, 2)}:${newText.substring(2)}';
    }

    // 4. Возвращаем новое значение и ставим курсор в конец
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
