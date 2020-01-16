class Result<T> {
  /// Indicates if the request was successfull or not
  ///
  /// Returns true if data is not null and there're no error messages, otherwise returns false
  bool get isSuccess {
    var res = data != null && errorMessages.isEmpty;
    if (res) {
      if (data is String) {
        res = (data as String).isNotEmpty;
      }
    }

    return res;
  }

  T data;
  List<String> errorMessages = <String>[];
}
