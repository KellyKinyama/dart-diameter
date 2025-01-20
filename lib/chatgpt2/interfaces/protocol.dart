class DiameterProtocolImpl implements DiameterProtocol {
  @override
  List<DiameterCommand> get commands => [
        RARCommand(),
        ACRCommand(),
        ROCommand(),
        // Add other commands here
      ];

  @override
  void handleRequest(Uint8List messageData) {
    // Decode the message and find the corresponding command
    DiameterMessage message = decodeMessage(messageData);
    DiameterCommand? command = findCommand(message.commandCode);

    if (command != null && command.isValidRequest(message)) {
      // Execute the command with the message
      command.execute(message);
    } else {
      print("Invalid command or message.");
    }
  }

  @override
  void sendMessage(DiameterMessage message) {
    // Logic for sending the message (e.g., over network)
    print("Sending message: ${message.commandCode}");
  }

  @override
  DiameterMessage decodeMessage(Uint8List data) {
    // Decode the Diameter message from the byte stream
    return DiameterMessage.decode(data);
  }

  @override
  DiameterCommand? findCommand(int commandCode) {
    // Search for the command based on command code
    return commands.firstWhere((command) => command.commandCode == commandCode,
        orElse: () => null);
  }
}
