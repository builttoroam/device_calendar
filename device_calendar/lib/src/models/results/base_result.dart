part of device_calendar;

class BaseResult<T> {
  bool isSuccess = false;
  T data;
  List<String> errorMessages = new List<String>();

  BaseResult([this.data]);
}
