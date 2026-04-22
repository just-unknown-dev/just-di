import 'package:flutter_test/flutter_test.dart';
import 'package:just_di/just_di.dart';

void main() {
  tearDown(() {
    JustDi.reset();
  });

  group('JustDi', () {
    test('registers and resolves singleton instances', () {
      final service = _CounterService();

      JustDi.registerSingleton<_CounterService>(service);

      expect(JustDi.get<_CounterService>(), same(service));
      expect(JustDi.isRegistered<_CounterService>(), isTrue);
    });

    test('creates lazy singletons only once', () {
      var createCount = 0;

      JustDi.registerLazySingleton<_CounterService>(() {
        createCount++;
        return _CounterService();
      });

      final first = JustDi.get<_CounterService>();
      final second = JustDi.get<_CounterService>();

      expect(first, same(second));
      expect(createCount, 1);
    });

    test('creates new instances for factories', () {
      JustDi.registerFactory<_CounterService>(() => _CounterService());

      final first = JustDi.get<_CounterService>();
      final second = JustDi.get<_CounterService>();

      expect(first, isNot(same(second)));
    });

    test('scopes override parent registrations', () {
      final global = _NamedService('global');
      final local = _NamedService('local');

      JustDi.registerSingleton<_NamedService>(global);
      final scope = JustDi.createScope();
      scope.registerSingleton<_NamedService>(local);

      expect(JustDi.get<_NamedService>().name, 'global');
      expect(scope.get<_NamedService>().name, 'local');
    });

    test('scope disposal disposes only local services', () {
      var globalDisposed = 0;
      var localDisposed = 0;

      JustDi.registerSingleton<_DisposableService>(
        _DisposableService(),
        dispose: (_) => globalDisposed++,
      );

      final scope = JustDi.createScope();
      scope.registerSingleton<_CounterService>(
        _CounterService(),
        dispose: (_) => localDisposed++,
      );

      scope.close();

      expect(localDisposed, 1);
      expect(globalDisposed, 0);
    });

    test('returns null for missing optional services', () {
      expect(JustDi.getOrNull<_CounterService>(), isNull);
    });
  });
}

class _CounterService {}

class _DisposableService {}

class _NamedService {
  _NamedService(this.name);

  final String name;
}
