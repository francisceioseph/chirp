// lib/src/platform/file_picker.dart
//
// O seletor de arquivos do sistema (o do GTK, o do Windows, o do macOS, o do Android e
// o do iOS, pelo file_selector), atrás de uma interface para os testes trocarem.
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

abstract interface class FilePicker {
  /// Um arquivo para mandar; `null` se quem usa desistiu.
  Future<String?> pickFile();

  /// Onde salvar uma cópia de [name]; `null` se desistiu ou se o sistema não tem
  /// onde (o iOS, por enquanto).
  Future<String?> saveLocation(String name);

  /// O sistema deixa escolher onde salvar.
  bool get canSave;
}

class SystemFilePicker implements FilePicker {
  const SystemFilePicker();

  @override
  Future<String?> pickFile() async => (await openFile())?.path;

  @override
  bool get canSave => defaultTargetPlatform != TargetPlatform.iOS;

  @override
  Future<String?> saveLocation(String name) async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // No Android, escolhe a pasta, e o arquivo vai com o nome dele.
        final dir = await getDirectoryPath();
        return dir == null ? null : '$dir/$name';
      case TargetPlatform.iOS:
        return null;
      default:
        return (await getSaveLocation(suggestedName: name))?.path;
    }
  }
}

/// O seletor que o app usa, posto no alto da árvore pelo ChirpApp.
class FilePickerScope extends InheritedWidget {
  const FilePickerScope({
    super.key,
    required this.picker,
    required super.child,
  });

  final FilePicker picker;

  static FilePicker of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FilePickerScope>()?.picker ??
      const SystemFilePicker();

  @override
  bool updateShouldNotify(FilePickerScope oldWidget) =>
      picker != oldWidget.picker;
}
