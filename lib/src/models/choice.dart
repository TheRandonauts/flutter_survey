import 'package:meta/meta.dart';
import '../models/question.dart';

@immutable
class Choice {
  /// Stable machine ID for analytics/storage (e.g., "ig", "rig", "themes").
  final String id;

  /// User-visible label (localizable).
  final String label;

  /// Optional follow-up questions when this label is selected.
  final List<Question>? children;

  const Choice(this.id, this.label, [this.children]);
}

extension ChoiceBuild on List<Choice> {
  /// label -> children?
  Map<String, List<Question>?> toAnswerChoices() =>
      {for (final c in this) c.label: c.children};

  /// label -> stable id
  Map<String, String> toAnswerChoiceIds() =>
      {for (final c in this) c.label: c.id};
}
