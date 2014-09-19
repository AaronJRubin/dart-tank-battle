#!/usr/bin/env python
#
# Copyright 2007 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
import os
import webapp2
import jinja2
import string
import json
import logging

template_dir = os.path.join(os.path.dirname(__file__), 'templates')
jinja_env = jinja2.Environment(loader = jinja2.FileSystemLoader(template_dir))

class PlayerFormInput:
    keys = list(string.ascii_uppercase) + list(string.digits) + ['LEFT', 'RIGHT', 'UP', 'DOWN']
    colors = ['RED', 'ORANGE', 'YELLOW', 'GREEN', 'BLUE', 'VIOLET']

    def __init__(self, number, left = "LEFT", right = "RIGHT", accelerate = "UP", reverse = "DOWN", color = "RED"):
        self.number = number
        self.left = left
        self.right = right
        self.accelerate = accelerate
        self.reverse = reverse
        self.color = color

    def render(self):
        return render_str("player-form-input.html", player = self, keys = self.keys, colors = self.colors)

    def to_dic(self):
        to_return = {}
        to_return["number"] = self.number
        to_return["left"] = self.left
        to_return["right"] = self.right
        to_return["accelerate"] = self.accelerate
        to_return["reverse"] = self.reverse
        to_return["color"] = self.color
        return to_return

def render_str(template, **params):
    t = jinja_env.get_template(template)
    return t.render(**params)

class Handler(webapp2.RequestHandler):
    def write(self, *a, **kw):
        self.response.out.write(*a, **kw)

    def render_str(self, template, **params):
        t = jinja_env.get_template(template)
        return t.render(**params)

    def render(self, template, **params):
        self.write(self.render_str(template, **params))

class MainHandler(Handler):
    def get(self):
        self.redirect("/game-settings.html");

class BouncyBallBattleSettings(Handler):    
    def get(self):
        player2 = PlayerFormInput("2")
        player1 = PlayerFormInput("1", "A", "D", "W", "S", color = 'GREEN')
        player3 = PlayerFormInput("3", "J", "L", "I", "K", color = 'YELLOW')
        player4 = PlayerFormInput("4", "7", "9", "8", "0", color = 'BLUE')
        players = [player1, player2, player3, player4]
        self.render("game-settings.html", players = players)
            
class BouncyBallBattlePlay(Handler):
    def get(self):
        self.redirect("/bouncy-ball-battle.html")

app = webapp2.WSGIApplication([
    ('/', MainHandler), ('/bouncyballbattle/settings', BouncyBallBattleSettings),  ('/bouncyballbattle/play', BouncyBallBattlePlay)
], debug=True)
