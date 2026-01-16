/// Represents the strategy for handling goal debt (shortfall)
enum DebtStrategy {
  ignore, // Don't carry over shortfall
  carryForward, // Add shortfall to next period
  distributeEvenly; // Spread shortfall over next N periods

  int get value => index;

  static DebtStrategy fromValue(int value) {
    return DebtStrategy.values[value];
  }
}
