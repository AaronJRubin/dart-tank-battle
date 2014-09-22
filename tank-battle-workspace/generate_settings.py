import jinja2
import os
import string

template_dir = os.path.join(os.path.dirname(__file__), 'templates')
jinja_env = jinja2.Environment(loader = jinja2.FileSystemLoader(template_dir))

class PlayerFormInput:
    keys = list(string.ascii_uppercase) + list(string.digits) + ['LEFT', 'RIGHT', 'UP', 'DOWN']
    colors = ['RED', 'ORANGE', 'YELLOW', 'GREEN', 'BLUE', 'VIOLET']

    def __init__(self, number, left = "LEFT", right = "RIGHT", accelerate = "UP", reverse = "DOWN", color = "RED", use = True):
        self.number = number
        self.left = left
        self.right = right
        self.accelerate = accelerate
        self.reverse = reverse
        self.color = color
        self.use = use

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

player2 = PlayerFormInput("Two")
player1 = PlayerFormInput("One", "A", "D", "W", "S", color = 'GREEN')
player3 = PlayerFormInput("Three", "G", "J", "Y", "H", color = 'YELLOW', use = False)
player4 = PlayerFormInput("Four", "7", "9", "8", "0", color = 'BLUE', use = False)
players = [player1, player2, player3, player4]

renderedPage = render_str("game-settings-template.html", players = players)

file = open("web/game-settings.html", "w")

file.write(renderedPage)