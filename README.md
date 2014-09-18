This is the source code for the browser-based game hosted at http://aarons-website.appspot.com/game-settings.html, built with [Dart](https://www.dartlang.org/) and WebGL (more specifically, the [three.dart](https://github.com/threeDart/three.dart) port of the [three.js](http://www.threejs.org) library that abstracts away some of WebGL's complexity).

#Rationale

The inspiration of this project was to demonstrate the ease of making 3D browser games in Dart. For many programmers who come from a desktop gaming background, the dynamic typing of Javascript and absence of Java/C#/C++ style classical inheritance provides a significant barrier to entry, and Dart provides an excellent alternative. There are, of course, other ways to write games that run in the browser using statically typed, object-oriented languages, such as the Unity game engine and Typescript. Unity, however, requires a browser plugin, which for some users can be a barrier to entry. Typescript is a superscript of Javascript, rather than a clean break, and lacks support for some features that many developers are used to such as abstract classes. Additionally, Dart has the advantage of performing better than Javascript when run in the Dart VM, and while no browsers have embedded the Dart VM as of 9/9/14, there are hopes that we'll eventually see it in Chrome, at least.

#Overview

The entry point for the user of this application is game-settings.html, where the user selects the number of players, their color, the desired control scheme (although the default key configuration is probably optimal for most machines), and the game stage to be used. The user interface elements for the game settings were built using [Polymer](http://www.polymer-project.org/), a library built on top of HTML5 web components technology. Polymer's advantage is that it allows for the defining of custom elements whose behavior is defined by Dart code, and these custom elements can be composed to form new elements and to write very semantic, readable HTML.

```
 <player-input id="player-1" leftKey="A" rightKey="D" accelerateKey="W" reverseKey="S" color="ORANGE" name="Player 1" use="true"></player-input>
 <player-input id="player-2" leftKey="LEFT" rightKey="RIGHT" accelerateKey="UP" reverseKey="DOWN" color="RED" name="Player 2" use="true"></player-input>
 <player-input id="player-3" leftKey="G" rightKey="J" accelerateKey="Y" reverseKey="H" color="YELLOW" name="Player 3"></player-input>
 <player-input id="player-4" leftKey="7" rightKey="9" accelerateKey="8" reverseKey="0" color="GREEN" name="Player 4"></player-input>
```

Polymer's disadvantage is that it is currently in "developer preview," and still has a few quirks and bugs that need to be ironed out before it is really production-ready. It also does not play well with Safari at the time of the writing of this document.

After choosing settings and pressing the "Play" button, the settings are saved in HTML5 local browser storage and the user is taken to bouncy-ball-battle.html, where the script in bouncyballbattle.dart is run. This script reads the settings from local storage, initializes a list of RealisticMovementPlayers and a Stage accordingly, and starts a game loop in which the function updateLoop is called once per animation frame. This function uses a top-level defined instance of the Stopwatch class to determine the time elapsed since the previous animation frame and updates game objects (including players, bullets, and items) accordingly, as well as actually rendering the scene. A top-level defined instance of the Keyboard class, which keeps track of currently pressed keys, is passed to the players on each update, and this is how keyboard input is handled.