# Wedding Essentials Development Instructions

## Project

This is a Flutter application using:

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Provider for state management

## Development rules

- Work only on the feature requested in the current task.
- Do not modify unrelated screens or files.
- Preserve the current UI design and color palette.
- Reuse existing models, services, providers, and widgets.
- Do not replace working Firebase code with hard-coded data.
- Do not rename Firestore collections without explaining why.
- Do not add dependencies unless absolutely necessary.
- Detail screens must receive the selected document ID or model.
- Show loading, empty, and error states when appropriate.
- Use mounted or context.mounted after asynchronous operations.
- Do not start another feature automatically.

## Validation

After every task:

1. Run `dart format` on modified Dart files.
2. Run `flutter analyze`.
3. Fix errors introduced by the task.
4. Report which files were changed.
5. Stop and wait for the next task.