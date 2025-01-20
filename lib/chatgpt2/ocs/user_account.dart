class UserAccount {
  String userId;
  double balance;  // User's balance (could be in credits, money, etc.)
  DateTime lastUpdated;

  UserAccount({required this.userId, this.balance = 0.0, required this.lastUpdated});

  // Deduct balance based on the cost of a service
  bool deductBalance(double amount) {
    if (balance >= amount) {
      balance -= amount;
      lastUpdated = DateTime.now();
      return true;
    }
    return false;
  }

  // Add credits to the user's account
  void addCredits(double amount) {
    balance += amount;
    lastUpdated = DateTime.now();
  }

  // Check if the account has enough balance
  bool hasSufficientBalance(double amount) {
    return balance >= amount;
  }
}
