import 'dart:html';
import 'package:polymer/polymer.dart';
//import 'package:paper_elements/paper_icon_button.dart';
import 'player_input.dart';
//import 'package:paper_elements/paper_toggle_button.dart';
import 'package:paper_elements/paper_button.dart';
import 'stage.dart';
import 'package:three/extras/image_utils.dart';
import 'dart:convert';

main() {
  initPolymer();
  PaperButton playButton = document.querySelector("#play-button");
  playButton.onClick.listen((event) => play());
  preloadTextures();
}

/* Load these into the browser cache before the game begins,
 * so there aren't any weirdly untextured things during gameplay!
 * This is necessary because static initializers in Dart (which
 * are used to load textures - static instance variables -
 * in classes such as Player) are evaluated lazily, at first read rather
 * than at class load time. This means that the game can start
 * playing before all textures have been loaded, and that's no good.
 * For more information about the lazy initialization of statics,
 * see https://groups.google.com/a/dartlang.org/forum/#!topic/misc/dKurFjODRXQ
   */
void preloadTextures() {
  loadTexture('lava-stage-textures/boiled_flesh.jpg');
  loadTexture('lava-stage-textures/lava.jpg');
  loadTexture('lava-stage-textures/Lava_texture_by_Twister10.jpg');
  loadTexture('lava-stage-textures/william_wall_01_S.png');
  loadTexture('nine-pillar-stage-textures/particleenergyball-ss-alleffects.png');
  loadTexture('nine-pillar-stage-textures/rsz_1cloud--texture-3.jpg');
  loadTexture('night-sky/nightsky_back.jpg');
  loadTexture('night-sky/nightsky_front.jpg');
  loadTexture('night-sky/nightsky_left.jpg');
  loadTexture('night-sky/nightsky_right.jpg');
  loadTexture('night-sky/nightsky_top.jpg');
}

void play() {
  List<PlayerInput> playerInputs = document.getElementsByTagName('player-input');
  List<Map> playerMaps = [];
  for (PlayerInput playerInput in playerInputs) {
    Map playerMap = playerInput.getPlayerMap();
    if (playerMap != null) {
     // print(playerMap.toString());
      playerMaps.add(playerMap);
    }
  }
  Map settings = {};
  settings['players'] = playerMaps;
  SelectElement stageSelect = document.querySelector("#stage-select");
  String selectedStageName = stageSelect.selectedOptions[0].value;
  int selectedStage;
  switch(selectedStageName) {
    case ('basic-stage'):
      selectedStage = Stage.BASICSTAGE;
      break;
    case('nine-pillar-stage'):
      selectedStage = Stage.NINEPILLARSTAGE;
      break;
    case('nine-pillar-stage-mobile'):
      selectedStage = Stage.MOVINGNINEPILLARSTAGE;
      break;
    case('lava-walls'):
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
  window.location.assign("bouncy-ball-battle.html");
}