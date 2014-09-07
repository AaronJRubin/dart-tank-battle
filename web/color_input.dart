import 'package:polymer/polymer.dart';
import 'dart:html';

@CustomTag('color-input')
class ColorInput extends PolymerElement {
  final List<String> colors = toObservable(
       ["RED", "ORANGE", "YELLOW", "GREEN", "BLUE", "VIOLET"]);

  @published String defaultColor = "RED";

  ColorInput.created() : super.created() {
  }

  double _stringToHue(String input) {
      switch (input) {
        case 'RED':
          return 1.0;
        case 'BLUE':
          return 251 / 360;
        case 'GREEN':
          return 132 / 360;
        case 'ORANGE':
          return 31 / 360;
        case 'YELLOW':
          return 59 / 360;
        case 'VIOLET':
          return 293 / 360;
        default:
          return 0.0;
      }
    }

  double getHue() {
    SelectElement select = $["select"];
    List <OptionElement> options = select.selectedOptions;
      if (options.length < 1) {
        return null;
      } else {
        return _stringToHue(options[0].value);
      }
    }

}