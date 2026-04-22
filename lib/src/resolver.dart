typedef InstanceDisposer<T extends Object> = void Function(T instance);

abstract interface class Resolver {
  T get<T extends Object>({String? instanceName});

  T? getOrNull<T extends Object>({String? instanceName});

  bool isRegistered<T extends Object>({String? instanceName});
}
