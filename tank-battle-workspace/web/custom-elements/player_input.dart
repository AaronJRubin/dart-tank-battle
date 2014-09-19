import 'package:polymer/polymer.dart';
import 'package:paper_elements/paper_toggle_button.dart';
//import 'key_input.dart';

@CustomTag("player-input")
class PlayerInput extends PolymerElement {

  @published String leftKey = "LEFT";
  @published String rightKey = "RIGHT";
  @published String accelerateKey = "UP";
  @published String reverseKey = "DOWN";
  @published String color = "RED";
  @published String name="Bob";
  @published String use = "false";

  PlayerInput.created() : super.created() {
  }

  Map getPlayerMap() {
  //  print("Calling getPlayerMap!");
    PaperToggleButton usePlayer = $["usePlayer"];
    if (!usePlayer.checked) {
      return null;
    }
    int leftKey = $["leftKey"].getKey();
    int rightKey = $["rightKey"].getKey();
    int accelerateKey = $["accelerateKey"].getKey();
    int reverseKey = $["reverseKey"].getKey();
    double hue = $["color"].getHue();
    return {'left' : leftKey, 'right' : rightKey, 'accelerate' : accelerateKey, 'reverse' : reverseKey, 'hue' : hue, 'name' : name};
  }
}