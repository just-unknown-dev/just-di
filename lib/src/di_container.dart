import 'di_exception.dart';
import 'resolver.dart';

class DiContainer implements Resolver {
  DiContainer({DiContainer? parent}) : _parent = parent;

  final DiContainer? _parent;
  final Map<_ServiceKey, _Registration<Object>> _registrations = {};

  bool _isClosed = false;

  bool get isClosed => _isClosed;

  void registerSingleton<T extends Object>(
    T instance, {
    String? instanceName,
    InstanceDisposer<T>? dispose,
    bool override = false,
  }) {
    _register<T>(
      _ServiceKey(T, instanceName),
      _Registration<T>.singleton(instance, dispose: dispose),
      override: override,
    );
  }

  void registerLazySingleton<T extends Object>(
    T Function() factory, {
    String? instanceName,
    InstanceDisposer<T>? dispose,
    bool override = false,
  }) {
    _register<T>(
      _ServiceKey(T, instanceName),
      _Registration<T>.lazy(factory, dispose: dispose),
      override: override,
    );
  }

  void registerFactory<T extends Object>(
    T Function() factory, {
    String? instanceName,
    bool override = false,
  }) {
    _register<T>(
      _ServiceKey(T, instanceName),
      _Registration<T>.factory(factory),
      override: override,
    );
  }

  void _register<T extends Object>(
    _ServiceKey key,
    _Registration<T> registration, {
    required bool override,
  }) {
    _ensureOpen();

    if (_registrations.containsKey(key)) {
      if (!override) {
        throw DuplicateRegistrationException(key.type, key.instanceName);
      }
      _removeByKey(key, dispose: true);
    }

    _registrations[key] = registration as _Registration<Object>;
  }

  @override
  T get<T extends Object>({String? instanceName}) {
    return _resolve(_ServiceKey(T, instanceName)) as T;
  }

  Object _resolve(_ServiceKey key) {
    _ensureOpen();

    final registration = _registrations[key];
    if (registration != null) {
      return registration.resolve(key);
    }

    final parent = _parent;
    if (parent != null) {
      return parent._resolve(key);
    }

    throw ServiceNotFoundException(key.type, key.instanceName);
  }

  @override
  T? getOrNull<T extends Object>({String? instanceName}) {
    try {
      return get<T>(instanceName: instanceName);
    } on ServiceNotFoundException {
      return null;
    }
  }

  @override
  bool isRegistered<T extends Object>({String? instanceName}) {
    _ensureOpen();

    final key = _ServiceKey(T, instanceName);
    return _registrations.containsKey(key) ||
        (_parent?.isRegistered<T>(instanceName: instanceName) ?? false);
  }

  bool unregister<T extends Object>({
    String? instanceName,
    bool dispose = true,
  }) {
    _ensureOpen();
    return _removeByKey(_ServiceKey(T, instanceName), dispose: dispose);
  }

  bool _removeByKey(_ServiceKey key, {required bool dispose}) {
    final registration = _registrations.remove(key);
    if (registration == null) {
      return false;
    }

    if (dispose) {
      registration.disposeOwned();
    }

    return true;
  }

  void reset({bool dispose = true}) {
    _ensureOpen();

    final registrations = _registrations.values.toList(growable: false);
    _registrations.clear();

    if (!dispose) {
      return;
    }

    for (final registration in registrations.reversed) {
      registration.disposeOwned();
    }
  }

  DiScope createScope({String? debugLabel}) {
    _ensureOpen();
    return DiScope._(parent: this, debugLabel: debugLabel);
  }

  void close({bool dispose = true}) {
    if (_isClosed) {
      return;
    }

    reset(dispose: dispose);
    _isClosed = true;
  }

  void _ensureOpen() {
    if (_isClosed) {
      throw StateError('This dependency scope has already been closed.');
    }
  }
}

final class DiScope extends DiContainer {
  DiScope._({required super.parent, this.debugLabel});

  final String? debugLabel;
}

final class _ServiceKey {
  const _ServiceKey(this.type, this.instanceName);

  final Type type;
  final String? instanceName;

  @override
  bool operator ==(Object other) {
    return other is _ServiceKey &&
        other.type == type &&
        other.instanceName == instanceName;
  }

  @override
  int get hashCode => Object.hash(type, instanceName);
}

enum _RegistrationKind { singleton, lazySingleton, factory }

final class _Registration<T extends Object> {
  _Registration.singleton(this._cachedInstance, {this.dispose})
    : kind = _RegistrationKind.singleton,
      factory = null;

  _Registration.lazy(this.factory, {this.dispose})
    : kind = _RegistrationKind.lazySingleton;

  _Registration.factory(this.factory)
    : kind = _RegistrationKind.factory,
      dispose = null;

  final _RegistrationKind kind;
  final T Function()? factory;
  final InstanceDisposer<T>? dispose;

  T? _cachedInstance;
  bool _isCreating = false;

  T resolve(_ServiceKey key) {
    switch (kind) {
      case _RegistrationKind.singleton:
        return _cachedInstance as T;
      case _RegistrationKind.lazySingleton:
        final cached = _cachedInstance;
        if (cached != null) {
          return cached;
        }
        return _create(key, cache: true);
      case _RegistrationKind.factory:
        return _create(key, cache: false);
    }
  }

  T _create(_ServiceKey key, {required bool cache}) {
    if (_isCreating) {
      throw CircularDependencyException(key.type, key.instanceName);
    }

    final creator = factory;
    if (creator == null) {
      throw StateError('No factory is available for this registration.');
    }

    try {
      _isCreating = true;
      final created = creator();
      if (cache) {
        _cachedInstance = created;
      }
      return created;
    } finally {
      _isCreating = false;
    }
  }

  void disposeOwned() {
    final instance = _cachedInstance;
    if (instance != null) {
      dispose?.call(instance);
    }

    if (kind != _RegistrationKind.singleton) {
      _cachedInstance = null;
    }
  }
}
