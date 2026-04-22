import 'di_container.dart';
import 'resolver.dart';

abstract final class JustDi {
  static final DiContainer _global = DiContainer();

  static void registerSingleton<T extends Object>(
    T instance, {
    String? instanceName,
    InstanceDisposer<T>? dispose,
    bool override = false,
  }) {
    _global.registerSingleton<T>(
      instance,
      instanceName: instanceName,
      dispose: dispose,
      override: override,
    );
  }

  static void registerLazySingleton<T extends Object>(
    T Function() factory, {
    String? instanceName,
    InstanceDisposer<T>? dispose,
    bool override = false,
  }) {
    _global.registerLazySingleton<T>(
      factory,
      instanceName: instanceName,
      dispose: dispose,
      override: override,
    );
  }

  static void registerFactory<T extends Object>(
    T Function() factory, {
    String? instanceName,
    bool override = false,
  }) {
    _global.registerFactory<T>(
      factory,
      instanceName: instanceName,
      override: override,
    );
  }

  static T get<T extends Object>({String? instanceName}) {
    return _global.get<T>(instanceName: instanceName);
  }

  static T? getOrNull<T extends Object>({String? instanceName}) {
    return _global.getOrNull<T>(instanceName: instanceName);
  }

  static bool isRegistered<T extends Object>({String? instanceName}) {
    return _global.isRegistered<T>(instanceName: instanceName);
  }

  static bool unregister<T extends Object>({
    String? instanceName,
    bool dispose = true,
  }) {
    return _global.unregister<T>(instanceName: instanceName, dispose: dispose);
  }

  static void reset({bool dispose = true}) {
    _global.reset(dispose: dispose);
  }

  static DiScope createScope({String? debugLabel}) {
    return _global.createScope(debugLabel: debugLabel);
  }
}
