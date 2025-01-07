import '../diameter_message.dart';

abstract class DiameterCommandHandler {
  DiameterMessage handleRequest(DiameterMessage request);
}
