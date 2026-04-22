class DiException implements Exception {
  const DiException(this.message);

  final String message;

  @override
  String toString() => 'DiException: $message';
}

class ServiceNotFoundException extends DiException {
  ServiceNotFoundException(Type type, [String? instanceName])
    : super(
        instanceName == null
            ? 'No service registered for type $type.'
            : 'No service registered for type $type with name "$instanceName".',
      );
}

class DuplicateRegistrationException extends DiException {
  DuplicateRegistrationException(Type type, [String? instanceName])
    : super(
        instanceName == null
            ? 'A service is already registered for type $type.'
            : 'A service is already registered for type $type with name "$instanceName".',
      );
}

class CircularDependencyException extends DiException {
  CircularDependencyException(Type type, [String? instanceName])
    : super(
        instanceName == null
            ? 'Circular dependency detected while creating $type.'
            : 'Circular dependency detected while creating $type with name "$instanceName".',
      );
}
