// Preview adapter for the image_picker plugin.
// Covers: ImagePicker().pickImage and pickMedia returning the scenario's
// camera or photos fixture. Drop into .mobai/preview/flutter/mocks/.
import 'dart:io';

import 'package:preview_bridge/mobai_preview.dart';

enum ImageSource { camera, gallery }

class XFile {
  XFile(this.path, {String? name}) : name = name ?? path.split('/').last;

  final String path;
  final String name;

  Future<List<int>> readAsBytes() => File(path).readAsBytes();
}

class ImagePicker {
  Future<XFile?> pickImage({required ImageSource source, double? maxWidth, double? maxHeight, int? imageQuality}) async {
    final capability = source == ImageSource.camera ? 'camera' : 'photos';
    await MobAIPreview.permissions.request(capability);
    final image = source == ImageSource.camera
        ? await MobAIPreview.camera.pickImage()
        : await MobAIPreview.photos.pickImage();
    if (image == null) return null;
    // The preview hands over fixture bytes; the plugin's callers expect a
    // file path, so the adapter parks the bytes in a temp file.
    final file = File('${Directory.systemTemp.path}/${image.fileName}');
    await file.writeAsBytes(image.bytes, flush: true);
    return XFile(file.path, name: image.fileName);
  }

  Future<XFile?> pickMedia() => pickImage(source: ImageSource.gallery);
}
