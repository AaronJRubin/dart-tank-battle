import 'dart:html';
import 'stage.dart';
import 'dart:convert';

List<InputElement> playerCheckboxes = ["One", "Two", "Three", "Four"].map((id) => document.querySelector("#" + id + "-use")).toList(growable: false);

InputElement getPlayerCheckbox(String id) {
  return playerCheckboxes.where((checkbox) => checkbox.id == id + "-use").first;
}

bool isSelected(String playerID) {
  InputElement checkbox = getPlayerCheckbox(playerID);
  return checkbox.checked;
}

List<InputElement> selectedCheckboxes() {
  return ["One", "Two", "Three", "Four"].where(isSelected).toList(growable: false);
}


ButtonElement playButton = document.querySelector(".play-button");

main() {
  playerCheckboxes.forEach((checkbox) {
    checkbox.onClick.listen((onData) {
      if (selectedCheckboxes().length == 0) {
        playButton.disabled = true;
      } else {
        playButton.disabled = false;
      }
    });
  });
  playButton.onClick.listen((event) => play());
}

int stringToKeyCode(String input) {
  switch (input) {
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

double stringToHue(String input) {
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

Map getPlayerMap(String playerID) {
  SelectElement leftKeySelector = document.querySelector("#" + playerID + "-rotate-left");
  int leftKey = stringToKeyCode(leftKeySelector.selectedOptions.first.value);
  SelectElement rightKeySelector = document.querySelector("#" + playerID + "-rotate-right");
  int rightKey = stringToKeyCode(rightKeySelector.selectedOptions.first.value);
  SelectElement accelerateKeySelector = document.querySelector("#" + playerID + "-accelerate");
  int accelerateKey = stringToKeyCode(accelerateKeySelector.selectedOptions.first.value);
  SelectElement reverseKeySelector = document.querySelector("#" + playerID + "-reverse");
  int reverseKey = stringToKeyCode(reverseKeySelector.selectedOptions.first.value);
  SelectElement colorSelector = document.querySelector("#" + playerID + "-color");
  double hue = stringToHue(colorSelector.selectedOptions.first.value);
  return {
    'left': leftKey,
    'right': rightKey,
    'accelerate': accelerateKey,
    'reverse': reverseKey,
    'hue': hue,
    'name': 'Player' + playerID
  };
}




void play() {
  List<Map> playerMaps = ["One", "Two", "Three", "Four"].where(isSelected).map(getPlayerMap).toList();
  Map settings = {};
  settings['players'] = playerMaps;
  SelectElement stageSelect = document.querySelector("#stage-select");
  String selectedStageName = stageSelect.selectedOptions[0].value;
  int selectedStage;
  switch (selectedStageName) {
    case ('basic-stage'):
      selectedStage = Stage.BASICSTAGE;
      break;
    case ('nine-pillar-stage'):
      selectedStage = Stage.NINEPILLARSTAGE;
      break;
    case ('nine-pillar-stage-mobile'):
      selectedStage = Stage.MOVINGNINEPILLARSTAGE;
      break;
    case ('lava-walls'):
      selectedStage = Stage.LAVADEATHSTAGE;
      break;
    case ('lava-no-walls'):
      selectedStage = Stage.LAVADEATHSTAGENOWALLS;
      break;
    default:
      selectedStage = Stage.BASICSTAGE;
  }
  settings['stage'] = selectedStage;
  Storage localStorage = window.localStorage;
  String settingsString = JSON.encode(settings);
  // print("The following settingsString was generated " + settingsString);
  localStorage['settings'] = settingsString;
  print("About to redirect!");
  window.location.assign("bouncy-ball-battle.html");
}
