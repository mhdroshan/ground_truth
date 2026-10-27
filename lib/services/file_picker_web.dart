import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'file_picker_models.dart';

Future<PickedAttachment?> pickFilePlatform({String accept = '*/*'}) {
  final completer = Completer<PickedAttachment?>();
  final input = web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';
  input.accept = accept;

  input.onchange = ((web.Event _) {
    final files = input.files;
    if (files != null && files.length > 0) {
      final file = files.item(0)!;
      final reader = web.FileReader();
      reader.readAsDataURL(file);
      reader.onloadend = ((web.Event _) {
        final result = reader.result;
        String? dataUrl;
        if (result != null) {
          dataUrl = (result as JSString).toDart;
        }
        completer.complete(PickedAttachment(
          name: file.name,
          dataUrl: dataUrl,
          sizeBytes: file.size,
          mimeType: file.type,
        ));
      }).toJS;
      reader.onerror = ((web.Event _) {
        completer.complete(null);
      }).toJS;
    } else {
      completer.complete(null);
    }
  }).toJS;

  input.click();
  return completer.future;
}
