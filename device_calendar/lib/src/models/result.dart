part of device_calendar;

class Result<T> {
  bool isSuccess = false;
  T data;
  List<String> errorMessages = new List<String>();

    // TODO: Change to allow constructor parameter
  Result([this.data]);

   // TODO: Add wrapper to set data (and isSuccess to true)

   // TODO: To add error message (and set isSuccess to false);

}
