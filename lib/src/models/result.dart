class Result<T> {
  /// Indicates if the request was successfull or not
  ///
  /// Returns true if data is not null and there're no error messages, otherwise returns false
  bool get isSuccess {
    var res = data != null && errors.isEmpty;
    if (res) {
      if (data is String) {
        res = (data as String).isNotEmpty;
      }
    }

    return res;
  }

  /// Indicates if there are errors. This isn't exactly the same as !isSuccess since
  /// it doesn't look at the state of the data.
  ///
  /// Returns true if there are error messages, otherwise false
  bool get hasErrors {
    return errors.isNotEmpty;
  }

  T data;
  List<ResultError> errors = <ResultError>[];
}

class ResultError {
  final int errorCode;
  final String errorMessage;

  const ResultError(this.errorCode, this.errorMessage);
}
