import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../flutter_survey.dart';

part 'question.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Question extends Equatable {
  /// Optional stable machine ID (if you added this)
  final String? id;

  final String question;

  @JsonKey(defaultValue: true)
  final bool singleChoice;

  /// Branching: label -> list of follow-up questions
  @JsonKey(defaultValue: <String, List<Question>?>{})
  final Map<String, List<Question>?> answerChoices;

  /// Optional mapping label -> choice-id (e.g., "a1","a2")
  final Map<String, String>? answerChoiceIds;

  @JsonKey(defaultValue: false)
  final bool isMandatory;

  final String? errorText;

  final Map<String, dynamic>? properties;

  @JsonKey(defaultValue: false)
  final bool justText;

  /// Collected answers (labels for choices, or a single text value)
  @JsonKey(defaultValue: <String>[])
  final List<String> answers;

  const Question({
    this.id,
    required this.question,
    this.singleChoice = true,
    this.answerChoices = const <String, List<Question>?>{},
    this.answerChoiceIds,
    this.isMandatory = false,
    this.errorText,
    this.properties,
    this.answers = const <String>[],
    this.justText = false,
  });

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionToJson(this);

  Question copyWith({
    String? id,
    String? question,
    bool? singleChoice,
    Map<String, List<Question>?>? answerChoices,
    Map<String, String>? answerChoiceIds,
    bool? isMandatory,
    String? errorText,
    Map<String, dynamic>? properties,
    List<String>? answers,
    bool? justText,
  }) {
    return Question(
      id: id ?? this.id,
      question: question ?? this.question,
      singleChoice: singleChoice ?? this.singleChoice,
      answerChoices: answerChoices ?? this.answerChoices,
      answerChoiceIds: answerChoiceIds ?? this.answerChoiceIds,
      isMandatory: isMandatory ?? this.isMandatory,
      errorText: errorText ?? this.errorText,
      properties: properties ?? this.properties,
      answers: answers ?? this.answers,
      justText: justText ?? this.justText,
    );
  }

  // Add below your class declaration (keep json_serializable parts untouched)
  factory Question.single({
    String? id,
    required String question,
    required List<Choice> choices,
    bool isMandatory = false,
    String? errorText,
    Map<String, dynamic>? properties,
  }) {
    final props = Map<String, dynamic>.from(properties ?? const {});
    // prefer radio list for single-choice long labels; can be overridden by caller
    props.putIfAbsent('useRadioList', () => true);

    return Question(
      id: id,
      question: question,
      singleChoice: true,
      isMandatory: isMandatory,
      errorText: errorText,
      properties: props,
      answerChoices: choices.toAnswerChoices(),
      answerChoiceIds: choices.toAnswerChoiceIds(),
    );
  }

  factory Question.multi({
    String? id,
    required String question,
    required List<Choice> choices,
    bool isMandatory = false,
    String? errorText,
    Map<String, dynamic>? properties,
  }) {
    final props = Map<String, dynamic>.from(properties ?? const {});
    // prefer checkbox list for multi-select; can be overridden by caller
    props.putIfAbsent('useCheckboxList', () => true);

    return Question(
      id: id,
      question: question,
      singleChoice: false,
      isMandatory: isMandatory,
      errorText: errorText,
      properties: props,
      answerChoices: choices.toAnswerChoices(),
      answerChoiceIds: choices.toAnswerChoiceIds(),
    );
  }

  /// Convenience for a text-only info page (no input)
  factory Question.textPage({
    required String question,
    Map<String, dynamic>? properties,
  }) {
    return Question(
      question: question,
      justText: true,
      properties: properties,
    );
  }

  /// Convenience for a free-text input (no choices)
  factory Question.input({
    String? id,
    required String question,
    bool isMandatory = false,
    String? errorText,
    Map<String, dynamic>? properties,
  }) {
    return Question(
      id: id,
      question: question,
      isMandatory: isMandatory,
      errorText: errorText,
      properties: properties,
    );
  }


  @override
  List<Object?> get props => [
    id,
    question,
    singleChoice,
    answerChoices,
    answerChoiceIds,
    isMandatory,
    errorText,
    properties,
    justText,
    answers,
  ];
}
