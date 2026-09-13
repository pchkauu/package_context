import 'package:package_context/package_context.dart' as package_context;

import 'package_context_example.dart' as catalog;

/// Assigns a fresh test graph before a test in the current isolate.
///
/// Use this as a `setUp` callback and reset the context in `tearDown`, after
/// awaiting any pending binding. The in-memory host objects need no disposal.
void initializeTestContext() {
  const session = catalog.AppSession(userId: 'user-1');
  catalog.packageContext.initialize(
    package_context.PackageGraph(
      config: catalog.Config(
        baseUrl: Uri.parse('https://example.test'),
        isEnabled: true,
      ),
      dependencies: catalog.Dependencies(
        apiClient: catalog.MemoryApiClient(session: session),
        session: session,
      ),
    ),
  );
}
