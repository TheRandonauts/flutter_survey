import 'package:flutter/material.dart';

import '../models/question.dart';
import 'answer_choice_widget.dart';
import 'survey_form_field.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final void Function(List<String>) update;
  final FormFieldSetter<List<String>>? onSaved;
  final FormFieldValidator<List<String>>? validator;
  final AutovalidateMode? autovalidateMode;
  final String defaultErrorText;

  const QuestionCard({
    Key? key,
    required this.question,
    required this.update,
    this.onSaved,
    this.validator,
    this.autovalidateMode,
    required this.defaultErrorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Display question text only
          Container(
            padding: const EdgeInsets.only(left: 8, top: 15, bottom: 6),
            child: RichText(
              text: TextSpan(
                text: question.question,
                style: TextStyle(fontSize: 16),
                children: question.isMandatory
                    ? [
                        const TextSpan(
                          text: "*",
                          style: TextStyle(color: Colors.red),
                        )
                      ]
                    : null,
              ),
            ),
          ),

          /// If justText is true, do NOT render SurveyFormField
          if (!question.justText)
            SurveyFormField(
              defaultErrorText: defaultErrorText,
              question: question,
              onSaved: onSaved,
              validator: validator,
              autovalidateMode: autovalidateMode,
              builder: (FormFieldState<List<String>> state) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 6, bottom: 6),
                      child: AnswerChoiceWidget(
                        question: question,
                        onChange: (value) {
                          state.didChange(value);
                          update(value);
                        },
                      ),
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: Text(
                          state.errorText!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                );
              },
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
