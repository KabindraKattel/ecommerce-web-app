import '../exceptions/exceptions.dart';

class AndroidWebResourceErrorMessage {
  final int webErrorCode;

  const AndroidWebResourceErrorMessage(this.webErrorCode);

  String getMessage() {
    final errorType = webErrorCode;
    switch (errorType) {
      case -8: //timeout
        return const NetworkException().message;
      case -2: //hostLookup
        return const HostLookupException().message;
      case -6: //connect
        return const ServerException().message;
      default:
        return const OtherException().message;
    }
  }
}
