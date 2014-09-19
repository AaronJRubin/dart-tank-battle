library keyboard;

import 'dart:html';

class Keyboard {
  Set<int> _pressed = new Set<int>();

  bool isDown(int k) {
    return _pressed.contains(k);
  }

  void onKeyDown(KeyboardEvent e) {
    _pressed.add(e.keyCode);
  }

  void onKeyUp(KeyboardEvent e) {
    _pressed.remove(e.keyCode);
  }

  void bindToWindow() {
    window.addEventListener('keyup', (Event e) => onKeyUp(e));
    window.addEventListener('keydown', (Event e) => onKeyDown(e));
  }
}