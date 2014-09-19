import 'package:polymer/polymer.dart';
import 'dart:html';

@CustomTag('key-input')
class KeyInput extends PolymerElement {
 final List<String> keys = toObservable(
      ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
       "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "1", "2", "3", "4",
       "5", "6", "7", "8", "9", "0", "UP", "RIGHT", "DOWN", "LEFT"]);
 @published String defaultKey = "LEFT";

 KeyInput.created() : super.created() {
 }

 int _stringToKeyCode(String input) {
    switch(input) {
      case 'A':
        return KeyCode.A;
      case 'B':
        return KeyCode.B;
      case 'C':
        return KeyCode.C;
      case 'D':
        return KeyCode.D;
      case 'E':
        return KeyCode.E;
      case 'F':
        return KeyCode.F;
      case 'G':
        return KeyCode.G;
      case 'H':
        return KeyCode.H;
      case 'I':
        return KeyCode.I;
      case 'J':
        return KeyCode.J;
      case 'K':
        return KeyCode.K;
      case 'L':
        return KeyCode.L;
      case 'M':
        return KeyCode.M;
      case 'N':
        return KeyCode.N;
      case 'O':
        return KeyCode.O;
      case 'P':
        return KeyCode.P;
      case 'Q':
        return KeyCode.Q;
      case 'R':
        return KeyCode.R;
      case 'S':
        return KeyCode.S;
      case 'T':
        return KeyCode.T;
      case 'U':
        return KeyCode.U;
      case 'V':
        return KeyCode.V;
      case 'W':
        return KeyCode.W;
      case 'X':
        return KeyCode.X;
      case 'Y':
        return KeyCode.Y;
      case 'Z':
        return KeyCode.Z;
      case '1':
        return KeyCode.ONE;
      case '2':
        return KeyCode.TWO;
      case '3':
        return KeyCode.THREE;
      case '4':
        return KeyCode.FOUR;
      case '5':
        return KeyCode.FIVE;
      case '6':
        return KeyCode.SIX;
      case '7':
        return KeyCode.SEVEN;
      case '8':
        return KeyCode.EIGHT;
      case '9':
        return KeyCode.NINE;
      case '0':
        return KeyCode.NINE;
      case 'LEFT':
        return KeyCode.LEFT;
      case 'RIGHT':
        return KeyCode.RIGHT;
      case 'UP':
        return KeyCode.UP;
      case 'DOWN':
        return KeyCode.DOWN;
      default:
        return KeyCode.UNKNOWN;
    }
  }

  int getKey() {
    SelectElement select = $["select"];
    List<OptionElement> selectedOptions = select.selectedOptions;
    if (selectedOptions.length == 0) {
      return null;
    } else {
      return _stringToKeyCode(selectedOptions[0].value);
    }
  }
}