// ignore_for_file: avoid_print

import 'package:just_di/just_di.dart';

// --- Service interfaces ---

abstract interface class Logger {
  void log(String message);
}

abstract interface class Database {
  void query(String sql);
}

// --- Concrete implementations ---

class ConsoleLogger implements Logger {
  @override
  void log(String message) => print('[LOG] $message');
}

class AppDatabase implements Database {
  AppDatabase(this._logger);

  final Logger _logger;

  @override
  void query(String sql) {
    _logger.log('Query: $sql');
  }

  void close() => print('[DB] Connection closed.');
}

class RequestContext {
  RequestContext(this.requestId);

  final String requestId;

  @override
  String toString() => 'RequestContext(id: $requestId)';
}

// --- Example 1: Global container via JustDi facade ---

void globalFacadeExample() {
  print('\n=== Example 1: Global facade ===');

  // Eager singleton — same instance every time.
  JustDi.registerSingleton<Logger>(ConsoleLogger());

  // Lazy singleton — created on first access, then cached.
  JustDi.registerLazySingleton<Database>(
    () => AppDatabase(JustDi.get<Logger>()),
    dispose: (db) => (db as AppDatabase).close(),
  );

  final logger = JustDi.get<Logger>();
  logger.log('App started');

  final db = JustDi.get<Database>();
  db.query('SELECT * FROM users');

  // Same instance is returned on subsequent calls.
  assert(identical(JustDi.get<Logger>(), logger));

  JustDi.reset(); // disposes all registered instances
}

// --- Example 2: Factory registrations ---

void factoryExample() {
  print('\n=== Example 2: Factory ===');

  JustDi.registerFactory<RequestContext>(
    () => RequestContext('req-${DateTime.now().microsecondsSinceEpoch}'),
  );

  // A fresh instance is returned on every call.
  final ctx1 = JustDi.get<RequestContext>();
  final ctx2 = JustDi.get<RequestContext>();
  print(ctx1);
  print(ctx2);
  assert(!identical(ctx1, ctx2));

  JustDi.reset();
}

// --- Example 3: Named instances ---

void namedInstancesExample() {
  print('\n=== Example 3: Named instances ===');

  JustDi.registerSingleton<Logger>(ConsoleLogger(), instanceName: 'verbose');
  JustDi.registerSingleton<Logger>(ConsoleLogger(), instanceName: 'silent');

  JustDi.get<Logger>(instanceName: 'verbose').log('verbose logger');
  JustDi.get<Logger>(instanceName: 'silent').log('silent logger');

  JustDi.reset();
}

// --- Example 4: Scoped container (child scope) ---

void scopedContainerExample() {
  print('\n=== Example 4: Scoped container ===');

  // Root container holds the shared logger.
  JustDi.registerSingleton<Logger>(ConsoleLogger());

  // Create a child scope for a request lifetime.
  final scope = JustDi.createScope(debugLabel: 'request-scope');

  // Register request-scoped services inside the scope.
  scope.registerFactory<RequestContext>(() => RequestContext('scoped-req'));

  // The scope inherits registrations from the parent.
  final logger = scope.get<Logger>(); // resolved from root
  logger.log('Inside scope');

  final ctx = scope.get<RequestContext>(); // resolved from scope
  print(ctx);

  scope.close(); // disposes only scope-local registrations

  JustDi.reset();
}

// --- Example 5: DiContainer used standalone ---

void standaloneContainerExample() {
  print('\n=== Example 5: Standalone DiContainer ===');

  final container = DiContainer();

  container.registerSingleton<Logger>(ConsoleLogger());
  container.registerLazySingleton<Database>(
    () => AppDatabase(container.get<Logger>()),
    dispose: (db) => (db as AppDatabase).close(),
  );

  container.get<Logger>().log('Using standalone container');
  container.get<Database>().query('SELECT 1');

  print('isRegistered<Logger>: ${container.isRegistered<Logger>()}');
  print(
    'isRegistered<RequestContext>: ${container.isRegistered<RequestContext>()}',
  );

  final removed = container.unregister<Logger>(dispose: false);
  print('Logger unregistered: $removed');

  final logger = container.getOrNull<Logger>();
  print('getOrNull after unregister: $logger'); // null

  container.close();
}

// --- Entry point ---

void main() {
  globalFacadeExample();
  factoryExample();
  namedInstancesExample();
  scopedContainerExample();
  standaloneContainerExample();
}
