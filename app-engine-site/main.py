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
        self.redirect("/game-settings.html")
            
class BouncyBallBattlePlay(Handler):
    def get(self):
        self.redirect("/bouncy-ball-battle.html")

app = webapp2.WSGIApplication([
    ('/', MainHandler), ('/bouncyballbattle/settings', BouncyBallBattleSettings),  ('/bouncyballbattle/play', BouncyBallBattlePlay)
], debug=True)
