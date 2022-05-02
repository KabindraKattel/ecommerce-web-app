class NetworkException implements Exception {
  final String message;
  const NetworkException({this.message = 'No Internet Connection'});
}

class ServerException implements Exception {
  final String message;
  const ServerException({this.message = 'Server Error Occurred'});
}

class HostLookupException implements Exception {
  final String message;
  const HostLookupException({this.message = 'Host Lookup Failed'});
}

class OtherException implements Exception {
  final String message;

  const OtherException({this.message = 'Some Error Occurred'});
}
