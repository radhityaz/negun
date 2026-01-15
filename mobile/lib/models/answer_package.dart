// models/answer_package.dart

class AnswerPackage {
  final AnswerHeader header;
  final String payload; // Encrypted string
  final String signature;

  AnswerPackage({required this.header, required this.payload, required this.signature});

  Map<String, dynamic> toJson() => {
    'header': header.toJson(),
    'payload': payload,
    'signature': signature,
  };
}

class AnswerHeader {
  final String examId;
  final String studentId;
  final String attemptId;
  final String deviceId;
  final DateTime submitTime;
  final String iv;

  AnswerHeader({
    required this.examId,
    required this.studentId,
    required this.attemptId,
    required this.deviceId,
    required this.submitTime,
    required this.iv,
  });

  Map<String, dynamic> toJson() => {
    'exam_id': examId,
    'student_id': studentId,
    'attempt_id': attemptId,
    'device_id': deviceId,
    'submit_time': submitTime.toIso8601String(),
    'iv': iv,
  };
}

class AnswerPayload {
  final List<AnswerItem> answers;
  final List<AuditLog> logs;

  AnswerPayload({required this.answers, required this.logs});

  Map<String, dynamic> toJson() => {
    'answers': answers.map((e) => e.toJson()).toList(),
    'logs': logs.map((e) => e.toJson()).toList(),
  };
}

class AnswerItem {
  final String questionId;
  final dynamic answer; // string or list
  final int timeSpent;

  AnswerItem({required this.questionId, required this.answer, required this.timeSpent});

  Map<String, dynamic> toJson() => {
    'q_id': questionId,
    'ans': answer,
    'time_spent_sec': timeSpent,
  };
}

class AuditLog {
  final String event;
  final DateTime timestamp;

  AuditLog({required this.event, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'event': event,
    'ts': timestamp.toIso8601String(),
  };
}
