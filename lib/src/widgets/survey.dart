// lib/src/widgets/survey.dart
import 'package:flutter/material.dart';
import 'package:flutter_survey/src/extensions/deep_copy.dart';

import '../models/question.dart';
import '../models/question_result.dart';
import 'question_card.dart';

typedef SurveyItemBuilder = Widget Function(
    BuildContext context,
    Question question,
    void Function(List<String> answers) update,
    );

/// Creates a Survey form with branching logic.
///
/// Enhancements added:
/// - Deterministic in-memory IDs for questions (`q1`, `q2`, ...) and answer choices (`a1`, `a2`, ...)
///   without changing the data model.
/// - Compact serializers you can call to persist locale-agnostic results:
///     - [buildCompactFlat] -> `{ "q1": "a2", "q2": ["a1","a3"], "q3": "free text" }`
///     - [buildCompactTree] -> `[{"q":"q1","a":["a2"],"children":[...]}]`
///
/// The public API remains compatible:
/// - `builder` still receives `(context, question, update)`.
/// - `onNext` still receives `List<QuestionResult>` built from the current answers.
///
class Survey extends StatefulWidget {
  /// The list of [Question] objects that dictate the flow and behaviour of the survey
  final List<Question> initialData;

  /// Function that returns a custom widget that is to be rendered as a field, preferably a [FormField]
  final SurveyItemBuilder? builder;

  /// A parameter to configure the default error message to be shown when validation fails.
  final String? defaultErrorText;

  /// Called after each answer is updated (advance). Receives the full results tree.
  final void Function(List<QuestionResult> results)? onNext;

  final void Function(Map<String, dynamic> flat)? onCompactFlat;
  final void Function(List<Map<String, dynamic>> tree)? onCompactTree;

  const Survey({
    Key? key,
    required this.initialData,
    this.builder,
    this.defaultErrorText,
    this.onNext,
    this.onCompactFlat,
    this.onCompactTree,
  }) : super(key: key);

  @override
  State<Survey> createState() => _SurveyState();
}

/// Controller to access compact serializers from outside the widget tree.
class SurveyController {
  _SurveyState? _state;

  Map<String, dynamic> buildCompactFlat() => _state!._buildCompactFlatFromState();
  List<Map<String, dynamic>> buildCompactTree() => _state!._buildCompactTreeFromState();
}

class _SurveyState extends State<Survey> {
  // The working copy of questions (we clone so we don't mutate the caller's objects)
  late List<Question> _surveyState;

  // In-memory ID registries that DO NOT require changes to the Question model.
  // Uses identity of the Question object as the key.
  final Map<Question, String> _qidByQuestion = {};
  final Map<Question, Map<String, String>> _choiceIdsByQuestion = {};

  // Reverse lookup by question text (best-effort for building legacy results)
  final Map<String, Question> _firstByText = {};

  // The builder we actually use (defaults to QuestionCard)
  late SurveyItemBuilder _builder;

  @override
  void initState() {
    super.initState();

    // Clone the incoming survey so local state is independent.
    _surveyState = widget.initialData.map((q) => q.clone()).toList();

    // Assign deterministic IDs (q1.., a1..) into the side maps.
    _assignDeterministicIds(_surveyState);

    // Choose builder
    if (widget.builder != null) {
      _builder = widget.builder!;
    } else {
      _builder = (context, model, update) => QuestionCard(
        key: ObjectKey(model),
        question: model,
        update: update,
        defaultErrorText: widget.defaultErrorText ?? 'This field is mandatory*',
        autovalidateMode: AutovalidateMode.onUserInteraction,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ----------------------------
  // Deterministic ID assignment
  // ----------------------------
  void _assignDeterministicIds(List<Question> roots) {
    int autoQ = 0;
    String nextQ() => 'q${++autoQ}';

    void dfs(List<Question> nodes) {
      for (final q in nodes) {
        // Prefer explicit Question.id; fallback to auto
        final explicitQid = q.id?.trim();
        final qid = (explicitQid != null && explicitQid.isNotEmpty)
            ? explicitQid
            : (_qidByQuestion[q] ?? nextQ());
        _qidByQuestion[q] = qid;

        // Build choice IDs: prefer explicit per-label IDs in the model; fallback to a1,a2...
        final labels = q.answerChoices.keys.toList();
        if (labels.isNotEmpty) {
          final byLabel = <String, String>{};
          for (var i = 0; i < labels.length; i++) {
            final label = labels[i];
            final exp = q.answerChoiceIds?[label]?.trim();
            byLabel[label] = (exp != null && exp.isNotEmpty) ? exp : 'a${i + 1}';
          }
          _choiceIdsByQuestion[q] = byLabel;
        }

        // Recurse into branches (for each label's children)
        for (final entry in q.answerChoices.entries) {
          final children = entry.value;
          if (children != null && children.isNotEmpty) {
            dfs(children);
          }
        }
      }
    }

    _qidByQuestion.clear();
    _choiceIdsByQuestion.clear();
    dfs(roots);
  }

  bool _useRadioList(Question q) {
    final p = q.properties;
    if (p == null) return false;
    final v = p['useRadioList'];
    return q.singleChoice && (v == true || v == 'true');
  }

  bool _useCheckboxList(Question q) {
    final p = q.properties;
    if (p == null) return false;
    final v = p['useCheckboxList'];
    return !q.singleChoice && (v == true || v == 'true');
  }

  String _registerQuestionId(Question q) {
    final id = q.id?.trim();
    if (id != null && id.isNotEmpty) {
      _qidByQuestion[q] = id;
    } else {
      _qidByQuestion[q] = 'q${_qidByQuestion.length + 1}';
    }
    if (q.answerChoices.isNotEmpty && !_choiceIdsByQuestion.containsKey(q)) {
      final labels = q.answerChoices.keys.toList();
      _choiceIdsByQuestion[q] = {
        for (var i = 0; i < labels.length; i++) labels[i]: 'a${i + 1}',
      };
    }
    return _qidByQuestion[q]!;
  }

  // -------------
  // UI rendering
  // -------------
  @override
  Widget build(BuildContext context) {
    final children = _buildChildren(_surveyState);
    // A simple scrollable list renders the dynamic tree.
    return ListView(
      padding: const EdgeInsets.all(12),
      children: children,
    );
  }

  List<Widget> _buildChildren(List<Question> questionNodes) {

    void _emitAll() {
      widget.onNext?.call(_mapCompletionData(_surveyState));
      if (widget.onCompactFlat != null) {
        widget.onCompactFlat!.call(_buildCompactFlatFromState());
      }
      if (widget.onCompactTree != null) {
        widget.onCompactTree!.call(_buildCompactTreeFromState());
      }
    }

    final list = <Widget>[];
    for (int i = 0; i < questionNodes.length; i++) {
      final q = questionNodes[i];

      final child = (widget.builder != null)
          ? _builder(context, q, (List<String> value) {
        q.answers
          ..clear()
          ..addAll(value);
        setState(() {});
        _emitAll();
      })
          : (_useRadioList(q)
          ? _RadioListQuestion(
        question: q,
        onChanged: (selectedLabel) {
          q.answers
            ..clear()
            ..add(selectedLabel); // ✅ write into Question.answers
          setState(() {});
          _emitAll();
        },
        defaultErrorText:
        widget.defaultErrorText ?? 'This field is mandatory*',
      )
          : _useCheckboxList(q)
          ? _CheckboxListQuestion(
        question: q,
        onChanged: (selectedLabels) {
          q.answers
            ..clear()
            ..addAll(selectedLabels); // ✅ write into Question.answers
          setState(() {});
          _emitAll();
        },
        defaultErrorText:
        widget.defaultErrorText ?? 'This field is mandatory*',
      )
          : QuestionCard(
        key: ObjectKey(q),
        question: q,
        update: (List<String> value) {
          q.answers
            ..clear()
            ..addAll(value); // ✅ already worked here
          setState(() {});
          _emitAll();
        },
        defaultErrorText:
        widget.defaultErrorText ?? 'This field is mandatory*',
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ));

    list.add(child);

    // If answered and it's a choice-type question, render any branched children
    if (_isAnswered(q) && _isNotSentenceQuestion(q)) {
    for (final answer in q.answers) {
    if (_hasAssociatedQuestionList(q, answer)) {
    list.addAll(_buildChildren(q.answerChoices[answer]!));
    }
    }
    }
  }
    return list;
  }


  bool _isAnswered(Question question) => question.answers.isNotEmpty;

  bool _isNotSentenceQuestion(Question question) => question.answerChoices.isNotEmpty;

  bool _hasAssociatedQuestionList(Question question, String answer) =>
      question.answerChoices[answer] != null;

  // ------------------------------
  // Legacy results tree builder
  // ------------------------------
  List<QuestionResult> _mapCompletionData(List<Question> questionNodes) {
    final result = <QuestionResult>[];
    for (final q in questionNodes) {
      // Only include questions that have been answered or justText pages (no input)
      if (q.justText || _isAnswered(q)) {
        final node = QuestionResult(question: q.question, answers: List<String>.from(q.answers));
        // For each selected answer, include any branched children
        if (_isNotSentenceQuestion(q)) {
          for (final answer in q.answers) {
            final children = q.answerChoices[answer];
            if (children != null && children.isNotEmpty) {
              node.children.addAll(_mapCompletionData(children));
            }
          }
        }
        result.add(node);
      }
    }
    return result;
  }

  // ---------------------------------------
  // Compact serializers (from current state)
  // ---------------------------------------

  /// Returns a compact *flat* map:
  ///   { "q1": "a2", "q2": ["a1","a3"], "q3": "free text" }
  Map<String, dynamic> _buildCompactFlatFromState() {
    if (_qidByQuestion.isEmpty) {
      _assignDeterministicIds(_surveyState);
    }
    final out = <String, dynamic>{};

    void visit(List<Question> nodes) {
      for (final q in nodes) {
        final qid = _qidByQuestion[q] ?? _registerQuestionId(q);

        final hasChoices = q.answerChoices.isNotEmpty;
        final isText = !hasChoices && !q.justText;

        if (isText) {
          out[qid] = q.answers.isNotEmpty ? q.answers.first : null;
        } else if (hasChoices) {
          final map = _choiceIdsByQuestion[q] ?? const <String, String>{};
          final ids = q.answers.map((label) => map[label] ?? label).toList();
          out[qid] = q.singleChoice
              ? (ids.isEmpty ? null : ids.first)
              : ids;
        }
        // Recurse only into selected branches
        if (hasChoices) {
          for (final label in q.answers) {
            final children = q.answerChoices[label];
            if (children != null && children.isNotEmpty) {
              visit(children);
            }
          }
        }
      }
    }

    visit(_surveyState);
    return out;
  }

  /// Returns a compact *tree* preserving branching:
  ///   [ {"q":"q1","a":["a2"],"children":[ ... ]} ]
  List<Map<String, dynamic>> _buildCompactTreeFromState() {
    if (_qidByQuestion.isEmpty) {
      _assignDeterministicIds(_surveyState);
    }
    Map<String, dynamic> nodeFor(Question q) {
      final qid = _qidByQuestion[q] ?? _registerQuestionId(q);
      final hasChoices = q.answerChoices.isNotEmpty;
      final isText = !hasChoices && !q.justText;

      if (isText) {
        return {
          "q": qid,
          "t": q.answers.isNotEmpty ? q.answers.first : null,
          "children": <Map<String, dynamic>>[],
        };
      }

      final childrenOut = <Map<String, dynamic>>[];
      if (hasChoices) {
        for (final label in q.answers) {
          final children = q.answerChoices[label];
          if (children != null && children.isNotEmpty) {
            for (final c in children) {
              childrenOut.add(nodeFor(c));
            }
          }
        }
      }

      if (hasChoices) {
        final map = _choiceIdsByQuestion[q] ?? const <String, String>{};
        final ids = q.answers.map((label) => map[label] ?? label).toList();
        return {"q": qid, "a": ids, "children": childrenOut};
      }

      // justText page
      return {"q": qid, "children": childrenOut};
    }

    final out = <Map<String, dynamic>>[];
    for (final q in _surveyState) {
      if (q.justText || _isAnswered(q)) {
        out.add(nodeFor(q));
      }
    }
    return out;
  }
}

class _RadioListQuestion extends StatefulWidget {
  const _RadioListQuestion({
    required this.question,
    required this.onChanged,
    required this.defaultErrorText,
  });

  final Question question;
  final void Function(String selectedLabel) onChanged;
  final String defaultErrorText;

  @override
  State<_RadioListQuestion> createState() => _RadioListQuestionState();
}

class _RadioListQuestionState extends State<_RadioListQuestion> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    // Seed from existing answer if present
    if (widget.question.answers.isNotEmpty) {
      _selected = widget.question.answers.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final labels = q.answerChoices.keys.toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question text
            Text(
              q.question,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Radio list
            ...labels.map((label) {
              return RadioListTile<String>(
                value: label,
                groupValue: _selected,
                onChanged: (val) {
                  setState(() => _selected = val);
                  if (val != null) widget.onChanged(val);
                },
                title: Text(label),
                contentPadding: EdgeInsets.zero,
                dense: false,
              );
            }),

            // Simple required error hint (optional)
            if (q.isMandatory && (_selected == null || _selected!.isEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.defaultErrorText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckboxListQuestion extends StatefulWidget {
  const _CheckboxListQuestion({
    required this.question,
    required this.onChanged,
    required this.defaultErrorText,
  });

  final Question question;
  final void Function(List<String> selectedLabels) onChanged;
  final String defaultErrorText;

  @override
  State<_CheckboxListQuestion> createState() => _CheckboxListQuestionState();
}

class _CheckboxListQuestionState extends State<_CheckboxListQuestion> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.question.answers.toSet();
  }

  void _toggle(String label, bool? checked) {
    setState(() {
      if (checked == true) {
        _selected.add(label);
      } else {
        _selected.remove(label);
      }
    });
    widget.onChanged(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final labels = q.answerChoices.keys.toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            // Checkbox list
            ...labels.map((label) {
              final checked = _selected.contains(label);
              return CheckboxListTile(
                value: checked,
                onChanged: (v) => _toggle(label, v),
                title: Text(label),
                contentPadding: EdgeInsets.zero,
                dense: false,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),

            // Simple required error hint (optional)
            if (q.isMandatory && _selected.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  widget.defaultErrorText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
