// Preview adapter for share_handler (federated, iOS/Android only).
// Mirrors the platform interface's data classes; nothing is ever shared into
// the preview, so the initial payload is null and the stream stays quiet.
import 'dart:async';

enum SharedAttachmentType { image, video, audio, file }

class SharedAttachment {
  SharedAttachment({required this.path, required this.type});
  String path;
  SharedAttachmentType type;
  Object encode() => <Object?, Object?>{'path': path, 'type': type.index};
  static SharedAttachment decode(Object message) {
    final map = message as Map<Object?, Object?>;
    return SharedAttachment(path: map['path']! as String, type: SharedAttachmentType.values[map['type']! as int]);
  }
}

class SharedMedia {
  SharedMedia({
    this.attachments,
    this.recipientIdentifiers,
    this.conversationIdentifier,
    this.content,
    this.speakableGroupName,
    this.serviceName,
    this.senderIdentifier,
    this.imageFilePath,
  });
  List<SharedAttachment?>? attachments;
  List<String?>? recipientIdentifiers;
  String? conversationIdentifier;
  String? content;
  String? speakableGroupName;
  String? serviceName;
  String? senderIdentifier;
  String? imageFilePath;
  Object encode() => <Object?, Object?>{
    'attachments': attachments?.map((a) => a?.encode()).toList(),
    'recipientIdentifiers': recipientIdentifiers,
    'conversationIdentifier': conversationIdentifier,
    'content': content,
    'speakableGroupName': speakableGroupName,
    'serviceName': serviceName,
    'senderIdentifier': senderIdentifier,
    'imageFilePath': imageFilePath,
  };
  static SharedMedia decode(Object message) {
    final map = message as Map<Object?, Object?>;
    return SharedMedia(
      attachments: (map['attachments'] as List<Object?>?)?.map((e) => SharedAttachment.decode(e as Map<Object?, Object?>)).cast<SharedAttachment?>().toList(),
      recipientIdentifiers: (map['recipientIdentifiers'] as List<Object?>?)?.cast<String?>(),
      conversationIdentifier: map['conversationIdentifier'] as String?,
      content: map['content'] as String?,
      speakableGroupName: map['speakableGroupName'] as String?,
      serviceName: map['serviceName'] as String?,
      senderIdentifier: map['senderIdentifier'] as String?,
      imageFilePath: map['imageFilePath'] as String?,
    );
  }
}

class ShareHandlerPlatform {
  static final ShareHandlerPlatform instance = ShareHandlerPlatform();
  final StreamController<SharedMedia> _controller = StreamController<SharedMedia>.broadcast();
  Future<SharedMedia?> getInitialSharedMedia() async => null;
  Future<void> resetInitialSharedMedia() async {}
  Stream<SharedMedia> get sharedMediaStream => _controller.stream;
}

class ShareHandler {
  static ShareHandlerPlatform get instance => ShareHandlerPlatform.instance;
}
