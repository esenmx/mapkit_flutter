import 'dart:io';

Future<void> main() async {
  final process = await Process.start('dart', ['run', 'pigeon', '--input', 'pigeons/messages.dart']);
  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);
  
  if (await process.exitCode != 0) {
    print('Pigeon generation failed.');
    exit(1);
  }

  final file = File('lib/src/messages.g.dart');
  var content = await file.readAsString();
  
  final target = '''
    for (final MapEntry<Object?, Object?> entryA in a.entries) {
      bool found = false;
      for (final MapEntry<Object?, Object?> entryB in b.entries) {
        if (_deepEquals(entryA.key, entryB.key)) {
          if (_deepEquals(entryA.value, entryB.value)) {
            found = true;
            break;
          } else {
            return false;
          }
        }
      }
      if (!found) {
        return false;
      }
    }
''';

  final replacement = '''
    for (final MapEntry<Object?, Object?> entryA in a.entries) {
      final Object? keyA = entryA.key;
      final Object? valueA = entryA.value;

      bool found = false;
      if (b.containsKey(keyA)) {
        if (_deepEquals(valueA, b[keyA])) {
          found = true;
        }
      }

      if (!found) {
        for (final MapEntry<Object?, Object?> entryB in b.entries) {
          if (_deepEquals(keyA, entryB.key)) {
            if (_deepEquals(valueA, entryB.value)) {
              found = true;
              break;
            } else {
              return false;
            }
          }
        }
      }

      if (!found) {
        return false;
      }
    }
''';

  if (content.contains(target)) {
    content = content.replaceFirst(target, replacement);
    await file.writeAsString(content);
    print('✅ Patched _deepEquals in messages.g.dart for O(N) complexity.');
  } else {
    print('⚠️ Could not find target _deepEquals block. Was Pigeon updated?');
  }
}
