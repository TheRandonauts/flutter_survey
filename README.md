<p align="center">
 <img src="https://user-images.githubusercontent.com/40787439/197688650-c68e9deb-f2d3-463c-b712-f8f03088fd78.svg" alt="Flutter Survey Logo" width="200"/>  
</p>
<p align="center">
<a href="https://pub.dev/packages/flutter_survey"><img src="https://img.shields.io/pub/v/flutter_survey.svg?" alt="Pub"></a>
<a href="https://codemagic.io/app/6358c75dd690310147230fea/build/679f5223970337b1e26d4ceb"><img src="https://api.codemagic.io/apps/6358c75dd690310147230fea/6358c75dd690310147230fe9/status_badge.svg" alt="License: MIT"></a>
<a href="https://github.com/flutter/packages/tree/main/packages/flutter_lints"><img src="https://img.shields.io/badge/style-flutter_lints-40c4ff.svg" alt="style: flutter lints"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

# <img src="https://user-images.githubusercontent.com/40787439/197688650-c68e9deb-f2d3-463c-b712-f8f03088fd78.svg" alt="Flutter Survey Logo" width="36"/> Flutter Survey — Randonautica Fork
Inspired by Google Forms

A simple yet powerful package for building dynamic questionnaires with **branching**, **compact results**, and **clean list UIs**.

<p align="left">
<img src="https://user-images.githubusercontent.com/40787439/197952319-310602aa-464c-413b-8cf2-e49b6ddebfbb.gif" alt="demo" width="220"/>
</p>

---

## 📋 What’s new in this fork
- **Compact, locale‑agnostic results** (no question/answer text):
  - **Flat map**: `{ "hear_about": "ig", "buy": ["rig","themes"] }`
  - **Branching tree**: `[{"q":"hear_about","a":["ig"],"children":[...]}]`
- **Stable IDs you control**
  - `Question.id` (e.g. `"hear_about"`). Fallback auto: `q1`, `q2`, …
  - `Question.answerChoiceIds` (label → id). Fallback auto: `a1`, `a2`, …
- **Ergonomic choice model**: `Choice(id, label, [children])` + convenience factories:
  - `Question.single(...)`, `Question.multi(...)`, `Question.input(...)`, `Question.textPage(...)`
- **List UIs for long labels**
  - Single choice → **Radio list** (opt‑in or via factories)
  - Multi choice → **Checkbox list** (opt‑in or via factories)
- **Zero breaking changes**
  - Your original `onNext(List<QuestionResult>)` is intact.
  - New compact results are available via **callbacks** (no controller needed).

---

## ⚙️ Install
Add to your app’s `pubspec.yaml` (use a local path if you work on the fork):
```yaml
dependencies:
  flutter_survey:
    path: ../flutter_survey
```

If you clone the repo or modify models, regenerate code:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 🧱 Data model (high‑level)
```dart
class Question {
  final String question;                              // UI text
  final bool singleChoice;                            // true=single, false=multi
  final Map<String, List<Question>?> answerChoices;   // label -> children?
  final bool isMandatory;
  final bool justText;                                // info page (no input)
  final String? errorText;
  final Map<String, dynamic>? properties;             // UI opts

  // New (optional; honored if set)
  final String? id;                                   // stable machine id
  final Map<String, String>? answerChoiceIds;         // label -> choice id
}
```

### `Choice` helper + factory constructors
```dart
// import 'package:flutter_survey/flutter_survey.dart';

const choices = [
  Choice('ig', 'Instagram'),
  Choice('tt', 'TikTok'),
  Choice('ot', 'Other', [Question.input(question: 'Other:')]),
];

final q1 = Question.single(
  id: 'hear_about',
  question: 'How did you first hear about Randonautica?',
  isMandatory: true,
  choices: choices,
);

final q2 = Question.multi(
  id: 'buy',
  question: 'What are you most likely to purchase?',
  choices: const [
    Choice('rig','Unlock the RIG'),
    Choice('themes','Unlock themes', [Question.input(question: 'Which themes?')]),
    Choice('none','Nothing'),
  ],
);
```

> The factories set sensible UI defaults: single→radio list, multi→checkbox list. You can still override per question via `properties`.

---

## 🚀 Usage
Pass your question list to `Survey`. You get both **verbose** (original) and **compact** results.

```dart
Survey(
  initialData: <Question>[
    Question.textPage(question: 'Welcome!'),
    q1,
    Question.input(id: 'intent', question: 'Share some intentions:'),
    q2,
  ],

  // Original verbose structure (still available)
  onNext: (resultsTree) {
    // final verbose = resultsTree.map((r) => r.toJson()).toList();
  },

  // New: compact results (no controller needed)
  onCompactFlat: (flat) => debugPrint('compactFlat: $flat'),
  // onCompactTree: (tree) => debugPrint('compactTree: $tree'),
);
```

---

## 🧭 Question types
- **Text Input** → no `answerChoices` (or use `Question.input`)
- **Single Choice** → `singleChoice: true` (or `Question.single`)
- **Multiple Choice** → `singleChoice: false` (or `Question.multi`)
- **Conditional / Nested** → provide children under a label
- **Informational page** → `justText: true` (or `Question.textPage`)

```dart
Question.single(
  id: 'coffee_like',
  question: 'Do you like coffee?',
  choices: const [
    Choice('yes','Yes', [
      Question.multi(
        id: 'brands',
        question: "What brands have you tried?",
        choices: const [Choice('nestle','Nestle'), Choice('sb','Starbucks')],
      ),
    ]),
    Choice('no','No'),
  ],
);
```

---

## 🎨 UI options
By default (via factories):
- Single choice → **RadioList** UI
- Multi choice → **CheckboxList** UI

You can override with `properties` per question:
```dart
Question(
  question: 'Example',
  singleChoice: true,
  properties: {'useRadioList': false}, // fall back to SlidingButtonRow
  answerChoices: const {'A': null, 'B': null},
);
```

---

## 📦 Results
- **Verbose (unchanged)** → `onNext(List<QuestionResult>)`.
- **Compact Flat** → recommended for storage/analytics:
  - Keys: `Question.id` if provided, else auto `qN`.
  - Values: `"choiceId"` / `["choiceId", ...]` / free text / `null`.
- **Compact Tree** → preserves branching:
  ```json
  [{"q":"hear_about","a":["ig"],"children":[{"q":"buy","a":["themes"]}]}]
  ```

IDs are your **explicit IDs** when set; otherwise deterministic `qN`/`aN` are used.

---

## ✅ Validation
- `isMandatory: true` → shows error until an answer is provided (use `errorText` or `Survey.defaultErrorText`).

---

## 🔄 Backward compatibility
- Your existing surveys and custom builders still work.
- No need to change persistence if you’re happy with verbose JSON.
- New compact callbacks are additive; use them when you want smaller, locale‑agnostic payloads.

---

## 🤝 Contributing
Bugs, feature ideas, and PRs are welcome!

## 📇 Author
Michel — <a href="https://www.linkedin.com/in/michel98">LinkedIn</a>