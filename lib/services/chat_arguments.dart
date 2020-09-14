class ScreenArguments {
  final String chatID;
  final String receiverName;
  final String receiverEmail;
  final String currentUser;
  ScreenArguments({
    this.chatID,
    this.receiverName,
    this.receiverEmail,
    this.currentUser,
  });
}

class RegistrationArguments {
  final String currentEmail;
  RegistrationArguments({
    this.currentEmail,
  });
}
