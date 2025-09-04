# flutter_survey (modified)

A flexible branching survey widget for Flutter.

This fork extends the original `flutter_survey` package with:

- **Compact, locale-agnostic result serialization** (flat or tree)
- **Deterministic IDs** for questions (`q1`, `q2`, …) and answer choices (`a1`, `a2`, …)
- **Optional radio-list UI** for single-choice questions
- **Optional checkbox-list UI** for multi-choice questions
- Full backward compatibility with the original verbose JSON results

---

## Features

- Create surveys with branching logic (answers can lead to follow-up questions).
- Display questions using the built-in **QuestionCard** (default).
- Switch to **radio lists** (single-choice) or **checkbox lists** (multi-choice) for better UX with longer answer texts.
- Get results in multiple formats:
    - Original **verbose JSON** (with full question + answer texts).
    - **Compact Flat** → `{ "q1": "a2", "q2": ["a1","a3"], "q3": "free text" }`
    - **Compact Tree** → `[{"q":"q1","a":["a2"],"children":[...]}]`

---

## Getting Started

### Define Questions

```dart
final questions = <Question>[
  // Intro (informational only)
  Question(
    question: 'Welcome!',
    justText: true,
    properties: {'subtitle': 'Tap “Start” to begin.'},
  ),

  // Single-choice with radio list
  Question(
    question: 'How was your experience?',
    singleChoice: true,
    isMandatory: true,
    properties: {'useRadioList': true}, // 👈 opt-in radio list
    answerChoices: {
      'Great': null,
      'Okay': null,
      'Not good': null,
    },
  ),

  // Multi-choice with checkbox list
  Question(
    question: 'Which things did you notice?',
    singleChoice: false,
    properties: {'useCheckboxList': true}, // 👈 opt-in checkbox list
    answerChoices: {
      'Animals': null,
      'People': null,
      'Symbols': null,
      'Synchronicities': null,
    },
  ),

  // Thank you screen
  Question(
    question: 'Thanks for completing the survey!',
    justText: true,
  ),
];
```

### Render the Survey

```dart
final controller = SurveyController();

Survey(
  initialData: questions,
  controller: controller,
  onNext: (resultsTree) {
    // Old verbose JSON (still available)
    final verbose = resultsTree.map((r) => r.toJson()).toList();

    // New compact serializers
    final compactFlat = controller.buildCompactFlat();
    final compactTree = controller.buildCompactTree();

    print('Verbose: $verbose');
    print('Compact flat: $compactFlat');
    print('Compact tree: $compactTree');
  },
);
```

---

## Results Formats

### Verbose JSON (original)
```json
[
  {
    "question": "How was your experience?",
    "answers": ["Great"],
    "children": []
  }
]
```

### Compact Flat
```json
{
  "q1": "a1",
  "q2": ["a1","a3"],
  "q3": "some free text"
}
```

### Compact Tree
```json
[
  {
    "q": "q1",
    "a": ["a1"],
    "children": [
      {
        "q": "q2",
        "a": ["a2"],
        "children": []
      }
    ]
  }
]
```

---

## UI Options

- **Default**: `SlidingButtonRow` for short, mobile-friendly options.
- **Radio List**: Use for single-choice questions with long answers.
  ```dart
  properties: {'useRadioList': true}
  ```
- **Checkbox List**: Use for multi-choice questions with long answers.
  ```dart
  properties: {'useCheckboxList': true}
  ```

---

## Compatibility

- All existing APIs are preserved.
- `onNext` still returns the original `List<QuestionResult>`.
- Compact serializers are optional via the `SurveyController`.

---

## Roadmap

- Global toggles (`preferListUIForSingle` / `preferListUIForMulti`) in `Survey` constructor.
- More customization hooks for builders.
- Searchable lists for long sets of answers.

---

## License

MIT (same as the original project).