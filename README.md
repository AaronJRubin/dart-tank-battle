This is the source code for the browser-based game hosted at http://aarons-website.appspot.com/game-settings.html, built with [Dart](https://www.dartlang.org/) and WebGL (more specifically, the [three.dart](https://github.com/threeDart/three.dart) port of the [three.js](http://www.threejs.org) library that abstracts away some of WebGL's complexity).

#Rationale

The inspiration of this project was to demonstrate the ease of making 3D browser games in Dart. For many programmers who come from a desktop gaming background, the dynamic typing of Javascript and absence of Java/C#/C++ style classical inheritance provides a significant barrier to entry, and Dart provides an excellent alternative. There are, of course, other ways to write games that run in the browser using statically typed, object-oriented languages, such as the Unity game engine and Typescript. Unity, however, requires a browser plugin, which for some users can be a barrier to entry. Typescript is a superscript of Javascript, rather than a clean break, and lacks support for some features that many developers are used to such as abstract classes. Additionally, Dart has the advantage of performing better than Javascript when run in the Dart VM, and while no browsers have embedded the Dart VM as of the time that this document was last updated, there are hopes that we'll eventually see it in Chrome, at least.

#How to Run the Code

The [tank-battle-workspace](tank-battle-workspace) directory contains the full directory tree for a Dart project, and can be imported into Dart Editor and run as-is, with game-settings.html as the entry point (though [test.html](test.html) and [bouncy-ball-battle.html](bouncy-ball-battle.html) can also be run if you're not interested in custom settings). The darttopy.sh script (which assumes that pub, the dart package and build manager, is on your PATH) runs darttojs and then copies the generated files into a new directory in [app-engine-site](app-engine-site) called "static" to allow them to be served using Google App Engine (Python SDK). The app engine site will not work unless that script is run first! You probably don't need to pay any attention to the app engine site, though, since the code of interest is all in [tank-battle-workspace](tank-battle-workspace) and it can be freely deployed to the server of your choice. It should be noted that because I use appcache to cache resources and allow for offline play, changes in the code will not be reflected in your browser unless you change [dart-tank-battle.appcache](tank-battle-workspace/web/dart-tank-battle.appcache), probably by changing the version comment at the top. Also note that [game-settings.html](tank-battle-workspace/web/game-settings.html) is generated by the python script in [tank-battle-workspace/generate_settings.py](tank-battle-workspace/generate_settings.py), which uses the Jinja2 templating engine. This approach allowed me to avoid repeating code for the many select boxes on that page, but it means that changes that you want to make to that file should be made by changing the [template](tank-battle-workspace/templates/game-settings-template.html), rather than by changing the [generated file in web](tank-battle-workspace/web/game-settings.html).

#Why not use [Polymer](http://www.polymer-project.org/)?

You might wonder why I used a Python templating engine to generate [game-settings.html](tank-battle-workspace/web/game-settings.html), rather than a Dart solution like [Polymer](http://www.polymer-project.org/). In fact, I did originally use Polymer for the user interface elements for the game settings. However, while I liked the semantic markup that Polymer provided, I found that the quirks and bugs associated with CSS encapsulation made responsive design difficult, that cross-browser support wasn't where I wanted it to be, and that there was a hefty performance overhead due to the dependencies involved. These problems might have been with Polymer itself, or they might been with my implementation of it, but in any event, I found Jinja2 to be a better solution for me.

For reference, this is the kind of markup that Polymer made possible, and that I used in a previous iteration of this project.

```
 <player-input id="player-1" leftKey="A" rightKey="D" accelerateKey="W" reverseKey="S" color="ORANGE" name="Player 1" use="true"></player-input>
 <player-input id="player-2" leftKey="LEFT" rightKey="RIGHT" accelerateKey="UP" reverseKey="DOWN" color="RED" name="Player 2" use="true"></player-input>
 <player-input id="player-3" leftKey="G" rightKey="J" accelerateKey="Y" reverseKey="H" color="YELLOW" name="Player 3"></player-input>
 <player-input id="player-4" leftKey="7" rightKey="9" accelerateKey="8" reverseKey="0" color="GREEN" name="Player 4"></player-input>
```

#Overview

The intended entry point for the user of this application is [game-settings.html](tank-battle-workspace/web/game-settings.html), where the user selects the number of players, their color, the desired control scheme (although the default key configuration is probably optimal for most machines), and the game stage to be used.  After choosing settings and pressing the "Play" button, the settings are saved in HTML5 local browser storage and the user is taken to bouncy-ball-battle.html, where the script in [bouncy_ball_battle.dart](tank-battle-workspace/web/bouncy_ball_battle.dart) is run. This script reads the settings from local storage, initializes a list of [RealisticMovementPlayers](web/player.dart) and a [Stage](tank-battle/workspace/web/stage.dart) accordingly, and uses them to initialize a [Game](tank-battle-workspace/web/game.dart). [Game](tank-battle-workspace/web/game.dart)'s update function, called with the time elapsed since the previous call, updates game objects (including [players](tank-battle-workspace/web/player.dart), [bullets](tank-battle-workspace/web/player.dart), and [items](tank-battle-workspace/item.dart)) and then renders the scene. This function is called every animation frame, and the time elapsed since the previous call is obtained via a top-level instance of the built-in [Stopwatch](https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/dart-core.Stopwatch) class. [Game](tank-battle-workspace/web/game.dart) has an instance of the [Keyboard](tank-battle-workspace/web/keyboard.dart) class, which keeps track of currently pressed keys, as an instance variable. The keyboard is passed to the players on each update, and that is how keyboard input is handled.

#Known Issues

WebGL has issues with transparency, in that sometimes textures with transparent backgrounds (needed for particle effects) fail to render at all. This results in the [Lightning Field](web/obstacles.dart)s in [Nine Pillar Lightning Stage](web/nine_pillar_stage.dart) suddenly seeming to vanish for no reason. This problem seems to occur much more frequently when running this game as compiled Javascript, rather than in the Dart VM, which suggests to me that performance issues are responsible. In addition, this problem seems to occur much more frequently when running on a computer with a relatively unimpressive GPU (like the Macbook Air), though more testing is needed to confirm this. If you encounter this problem when playing the game, just use a different stage! And if you have any ideas about how this issue could be addressed, I'd love to hear them.