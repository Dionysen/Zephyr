# local_json_store

Pure Dart JSON map persistence for application preferences. Construct a `JsonMapFileStore` with a directory provider, a relative file path, and an error message. A missing file returns `null`. Malformed JSON and I/O failures propagate to the caller. Parent directories are created on write, and writes are flushed to disk. Platform directory discovery stays in the host application.

```dart
final store = JsonMapFileStore(
  directoryProvider: () async => Directory('/app/support'),
  relativePath: 'my-app/preferences.json',
  invalidMessage: 'Invalid preferences.',
);
await store.write({'fontSize': 16});
final values = await store.read();
```
