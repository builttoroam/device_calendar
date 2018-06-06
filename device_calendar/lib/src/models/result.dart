part of device_calendar;

class Result<T> {
  bool get isSuccess {
    var res = data != null && errorMessages.length == 0;
    if (res) {
      if (data is String) {
        res = (data as String).isNotEmpty;
      }
    }

    return res;
  }

  T data;
  List<String> errorMessages = new List<String>();
}
