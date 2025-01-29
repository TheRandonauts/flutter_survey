import 'package:flutter/material.dart';

import '../models/question.dart';
import 'sliding_button_row.dart';

class AnswerChoiceWidget extends StatefulWidget {
  ///A callback function that must be called with the answer.
  final void Function(List<String> answers) onChange;

  ///The parameter that contains the data pertaining to a question.
  final Question question;

  const AnswerChoiceWidget(
      {Key? key, required this.question, required this.onChange})
      : super(key: key);

  @override
  State<AnswerChoiceWidget> createState() => _AnswerChoiceWidgetState();
}

class _AnswerChoiceWidgetState extends State<AnswerChoiceWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.question.answerChoices.isNotEmpty) {
      if (widget.question.singleChoice) {
        return SingleChoiceAnswer(
            onChange: widget.onChange, question: widget.question);
      } else {
        return MultipleChoiceAnswer(
            onChange: widget.onChange, question: widget.question);
      }
    } else {
      return SentenceAnswer(
        key: ObjectKey(widget.question),
        onChange: widget.onChange,
        question: widget.question,
      );
    }
  }
}


class SingleChoiceAnswer extends StatefulWidget {
  ///A callback function that must be called with the answer.
  final void Function(List<String> answers) onChange;

  ///The parameter that contains the data pertaining to a question.
  final Question question;

  const SingleChoiceAnswer({
    Key? key,
    required this.onChange,
    required this.question,
  }) : super(key: key);

  @override
  State<SingleChoiceAnswer> createState() => _SingleChoiceAnswerState();
}


class _SingleChoiceAnswerState extends State<SingleChoiceAnswer> {
  String? _selectedAnswer;

  @override
  void initState() {
    if (widget.question.answers.isNotEmpty) {
      _selectedAnswer = widget.question.answers.first;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Map answer choices to SlidingButtonRow format
    final List<Map<String, dynamic>> options = widget.question.answerChoices.keys.map((answer) {
      return {
        'text': answer,
        'active': _selectedAnswer == answer,
      };
    }).toList();

    return SlidingButtonRow(
      options: options,
      isMultipleSelection: false,
      initialSelection: _selectedAnswer != null
          ? [widget.question.answerChoices.keys.toList().indexOf(_selectedAnswer!)]
          : [],
      onSelectionChanged: (selectedIndices) {
        if (selectedIndices.isNotEmpty) {
          final selectedAnswer = widget.question.answerChoices.keys.toList()[selectedIndices.first];
          setState(() {
            _selectedAnswer = selectedAnswer;
          });
          widget.onChange([_selectedAnswer!]);
        }
      },
    );
  }
}

class MultipleChoiceAnswer extends StatefulWidget {
  ///A callback function that must be called with the answer.
  final void Function(List<String> answers) onChange;

  ///The parameter that contains the data pertaining to a question.
  final Question question;

  const MultipleChoiceAnswer({
    Key? key,
    required this.onChange,
    required this.question,
  }) : super(key: key);

  @override
  State<MultipleChoiceAnswer> createState() => _MultipleChoiceAnswerState();
}

class _MultipleChoiceAnswerState extends State<MultipleChoiceAnswer> {
  late List<String> _answers;

  @override
  void initState() {
    _answers = [];
    _answers.addAll(widget.question.answers);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Map answer choices to SlidingButtonRow format
    final List<Map<String, dynamic>> options = widget.question.answerChoices.keys.map((answer) {
      return {
        'text': answer,
        'active': _answers.contains(answer),
      };
    }).toList();

    return SlidingButtonRow(
      options: options,
      isMultipleSelection: true,
      initialSelection: _answers
          .map((answer) => widget.question.answerChoices.keys.toList().indexOf(answer))
          .toList(),
      onSelectionChanged: (selectedIndices) {
        final selectedAnswers = selectedIndices
            .map((index) => widget.question.answerChoices.keys.toList()[index])
            .toList();
        setState(() {
          _answers = selectedAnswers;
        });
        widget.onChange(_answers);
      },
    );
  }
}

class SentenceAnswer extends StatefulWidget {
  ///A callback function that must be called with the answer.
  final void Function(List<String> answers) onChange;

  ///The parameter that contains the data pertaining to a question.
  final Question question;
  const SentenceAnswer(
      {Key? key, required this.onChange, required this.question})
      : super(key: key);

  @override
  State<SentenceAnswer> createState() => _SentenceAnswerState();
}

class _SentenceAnswerState extends State<SentenceAnswer> {
  final TextEditingController _textEditingController = TextEditingController();
  @override
  void initState() {
    if (widget.question.answers.isNotEmpty) {
      _textEditingController.text = widget.question.answers.first;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextFormField(
        controller: _textEditingController,
        onChanged: (value) {
          widget.onChange([_textEditingController.text]);
        },
      ),
    );
  }
}
