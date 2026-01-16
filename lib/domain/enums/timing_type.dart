/// Defines how an event is scheduled in time
enum TimingType {
  /// Event has a fixed start and end time that cannot be changed by the app
  fixed(0),
  
  /// Event has flexible timing and can be scheduled by the app
  flexible(1);

  const TimingType(this.value);
  
  final int value;
  
  static TimingType fromValue(int value) {
    return TimingType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TimingType.flexible,
    );
  }
}
