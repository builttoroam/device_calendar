part of device_calendar;

class Result<T> {
  bool isSuccess = false;
  T data;
  List<String> errorMessages = new List<String>();

  Result([this.data]);
}
