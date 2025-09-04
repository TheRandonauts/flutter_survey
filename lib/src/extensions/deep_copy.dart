// lib/src/extensions/deep_copy.dart
//
// Deep cloning helpers for survey models.
// - Question.clone(): recursively clones branching graphs, including:
//     * id
//     * singleChoice, isMandatory, justText, errorText
//     * properties (shallow copy; see note below)
//     * answers (new list)
//     * answerChoiceIds (new map)
//     * answerChoices (deep copy of children lists)
// - QuestionResult.clone(): clones answers + children.
//
// NOTE about `properties`: This does a shallow Map copy. If you store
// nested objects/collections under `properties`, and you need a full deep
// JSON-style clone, replace `_cloneProps` with a JSON round-trip or a
// custom copier for your expected value types.

import 'package:flutter/foundation.dart' show listEquals, mapEquals;

import '../models/question.dart';
import '../models/question_result.dart';

extension DeepCopyQuestion on Question {
  /// Returns a deep copy of this [Question], including recursively cloned branches.
  Question clone() {
    // Clone simple fields
    final String? newId = id;
    final String newQuestionText = question; // non-null
    final bool newSingleChoice = singleChoice;
    final bool newIsMandatory = isMandatory;
    final bool newJustText = justText;
    final String? newErrorText = errorText;

    // Clone collections
    final Map<String, dynamic>? newProperties = _cloneProps(properties);
    final List<String> newAnswers = List<String>.from(answers);
    final Map<String, String>? newAnswerChoiceIds =
    answerChoiceIds == null ? null : Map<String, String>.from(answerChoiceIds!);

    // Deep clone branching: label -> list<Question>?
    final Map<String, List<Question>?> newAnswerChoices = <String, List<Question>?>{};
    answerChoices.forEach((label, children) {
      if (children == null) {
        newAnswerChoices[label] = null;
      } else {
        newAnswerChoices[label] = children.map((q) => q.clone()).toList();
      }
    });

    return Question(
      id: newId,
      question: newQuestionText, // now matches non-nullable type
      singleChoice: newSingleChoice,
      answerChoices: newAnswerChoices,
      answerChoiceIds: newAnswerChoiceIds,
      isMandatory: newIsMandatory,
      errorText: newErrorText,
      properties: newProperties,
      answers: newAnswers,
      justText: newJustText,
    );
  }
}

extension DeepCopyQuestionResult on QuestionResult {
  /// Deep copy of a [QuestionResult] node and its subtree.
  QuestionResult clone() {
    final copy = QuestionResult(
      question: question,
      answers: List<String>.from(answers),
    );
    for (final child in children) {
      copy.children.add(child.clone());
    }
    return copy;
  }
}

// ---------- Helpers ----------

Map<String, dynamic>? _cloneProps(Map<String, dynamic>? props) {
  if (props == null) return null;
  // Shallow copy; adjust if you store nested structures.
  return Map<String, dynamic>.from(props);
}
