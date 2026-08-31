import 'dart:async';
import 'dart:io';

const String kCheckInternetConnectionMessage = 'Check your internet connection';

bool isNetworkRelatedError(Object error) {
  final err = error.toString().toLowerCase();
  return error is SocketException ||
      error is TimeoutException ||
      err.contains('socketexception') ||
      err.contains('host lookup') ||
      err.contains('failed host lookup') ||
      err.contains('clientexception') ||
      err.contains('network is unreachable') ||
      err.contains('certificate_verify_failed') ||
      err.contains('handshake') ||
      err.contains('no internet connection') ||
      err.contains('timed out') ||
      err.contains('timeout');
}

String userFacingNetworkMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (isNetworkRelatedError(error)) {
    return kCheckInternetConnectionMessage;
  }
  return fallback;
}
