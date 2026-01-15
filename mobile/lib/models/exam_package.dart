// models/exam_package.dart

class ExamPackage {
  final ExamHeader header;
  final String payload; // Encrypted string
  final String signature;

  ExamPackage({required this.header, required this.payload, required this.signature});

  factory ExamPackage.fromJson(Map<String, dynamic> json) {
    return ExamPackage(
      header: ExamHeader.fromJson(json['header']),
      payload: json['payload'],
      signature: json['signature'],
    );
  }

  Map<String, dynamic> toJson() => {
    'header': header.toJson(),
    'payload': payload,
    'signature': signature,
  };
}

class ExamHeader {
  final String examId;
  final String title;
  final int version;
  final String encryptionIV;
  final DateTime validFrom;
  final DateTime validUntil;
  final int durationMins;

  ExamHeader({
    required this.examId,
    required this.title,
    required this.version,
    required this.encryptionIV,
    required this.validFrom,
    required this.validUntil,
    required this.durationMins,
  });

  factory ExamHeader.fromJson(Map<String, dynamic> json) {
    return ExamHeader(
      examId: json['exam_id'],
      title: json['title'],
      version: json['version'],
      encryptionIV: json['iv'],
      validFrom: DateTime.parse(json['valid_from']),
      validUntil: DateTime.parse(json['valid_until']),
      durationMins: json['duration_mins'],
    );
  }

  Map<String, dynamic> toJson() => {
    'exam_id': examId,
    'title': title,
    'version': version,
    'iv': encryptionIV,
    'valid_from': validFrom.toIso8601String(),
    'valid_until': validUntil.toIso8601String(),
    'duration_mins': durationMins,
  };
}

// Decrypted Payload
class ExamPayload {
  final List<Question> questions;
  final ExamConfig config;

  ExamPayload({required this.questions, required this.config});

  factory ExamPayload.fromJson(Map<String, dynamic> json) {
    var list = json['questions'] as List;
    List<Question> questionsList = list.map((i) => Question.fromJson(i)).toList();
    return ExamPayload(
      questions: questionsList,
      config: ExamConfig.fromJson(json['config']),
    );
  }
}

class ExamConfig {
  final bool allowWifi;
  final bool randomizeOrder;

  ExamConfig({required this.allowWifi, required this.randomizeOrder});

  factory ExamConfig.fromJson(Map<String, dynamic> json) {
    return ExamConfig(
      allowWifi: json['allow_wifi'] ?? false,
      randomizeOrder: json['randomize_order'] ?? false,
    );
  }
}

class Question {
  final String id;
  final String type;
  final String content;
  final List<Option> options;
  final int points;

  Question({required this.id, required this.type, required this.content, required this.options, required this.points});

  factory Question.fromJson(Map<String, dynamic> json) {
    var opts = json['options'] != null ? (json['options'] as List).map((i) => Option.fromJson(i)).toList() : <Option>[];
    return Question(
      id: json['id'],
      type: json['type'],
      content: json['content'],
      options: opts,
      points: json['points'],
    );
  }
}

class Option {
  final String id;
  final String content;

  Option({required this.id, required this.content});

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(id: json['id'], content: json['content']);
  }
}
