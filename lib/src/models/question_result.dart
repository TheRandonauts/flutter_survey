import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'question_result.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class QuestionResult extends Equatable {
  final String question; // existing (human text)
  late final List<QuestionResult> children;
  late final List<String> answers; // labels or free text

  QuestionResult({required this.question, List<String>? answers})
      : answers = answers ?? [],
        children = [];

  factory QuestionResult.fromJson(Map<String, dynamic> json) => _$QuestionResultFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionResultToJson(this);

  /// ---- New: Compact serialization helpers ----

  /// Build a compact *tree* node given a resolver label->ids and a questionId.
  Map<String, dynamic> toCompactTree({
    required String questionId,
    required String Function(String questionId, String label)? choiceIdResolver,
    required bool isTextAnswer,
  }) {
    if (isTextAnswer) {
      final t = (answers.isNotEmpty) ? answers.first : null;
      return {"q": questionId, "t": t, "children": children.map((c) => c.toJson()).toList()};
    } else {
      final ids = answers.map((label) => choiceIdResolver!(questionId, label)).toList();
      return {"q": questionId, "a": ids, "children": children.map((c) => c.toJson()).toList()};
    }
  }

  @override
  List<Object?> get props => [question, answers, children];
}