"""
Applet: WordOfTheDay
Summary: Displays the word of the day
Description: Fetches the word of the day from the Merriam-Webster website and displays it
Author: Paul Osburn
"""

# Word of the Day Tidbyt App
#
# Copyright (c) 2022 Paul Osburn
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

load("render.star", "render")
load("http.star", "http")
load("re.star", "re")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("schema.star", "schema")

# Constants
CACHE_KEY = "wordOfTheDay-saved_doc"
SITE_URL = "https://www.merriam-webster.com/word-of-the-day"

def main(config):
    """
    Displays the word of the day and its definition from the Merriam-Webster website

    Uses the custom marquee 'widget'

    Returns:
        A set of frames used to render an animated file

    """

    # Config
    theme_number = get_cfg_value(config, "theme", 0)

    # Check the cache first
    doc_cached = cache.get(CACHE_KEY)
    if doc_cached != None:
        print("Using cached data")
        doc = doc_cached
    else:
        # Otherwise fetch the web page
        print("Cache miss")
        rep = http.get(SITE_URL)
        if rep.status_code != 200:
            # Fail silently and display nothing
            doc = ""
        else:
            doc = rep.body()
            cache.set(CACHE_KEY, doc, ttl_seconds=240)

    # Word
    start = doc.find("<h1>") + 4
    end = doc.find("</h1>")
    word = doc[start:end].capitalize()

    # Definition
    def_start_token = "<h2>What It Means</h2>"
    def_start = doc.find(def_start_token) + len(def_start_token)
    def_end = doc.find("// ") - 10
    txt = doc[def_start:def_end]
    txt = txt.replace("<p>","").replace("</p>","")
    txt = txt.replace("<em>","").replace("</em>","")
    txt = txt.replace("// ","").replace("\"","")
    txt = txt.replace("</a>","")
    txt = txt.replace(word + " means ", "")
    txt = txt.replace("A " + word.lower() + " is ", "")
    
    # Remove anchor tags
    pattern = "<a[^>]*>"
    txt = re.sub(pattern, "", txt)

    definition = txt.lstrip().capitalize()

    def decToHex(dec):
        hex = "#000"
        if dec < 16:
            hex = str("#00%x" % dec)
        elif dec < 256: 
            hex = str("#0%x" % dec)
        else:
            hex = str("#%x" % dec)
        
        return hex

    def decreasing_color(color = "FF0000FF", step = 4):
        dec = int(color, 16)
        dec = max(0, dec - step)
        return decToHex(dec)

    def line(width = 64, height = 1, color = "FF0000FF", step = 4):
        return render.Row(
            children = [
                render.Box(
                    width = 1, 
                    height = height, 
                    color = decreasing_color(color, step = step * i)
                ) for i in range(width)
            ]
        )

    theme = THEME[theme_number]
    return render.Root(
        delay = 100,
        child = render.Padding(
            child = render.Column(
                children = [
                    render.Text(content = word, color = theme["title"]),
                    line(width = 64, height = 2, color = theme["line"], step = 3),
                    render.Padding(pad = (0, 1, 0, 0),                     
                        child = render.Animation(
                            custom_marquee(
                                definition, 
                                height = 21, 
                                font = "tom-thumb",
                                color = theme["definition"],
                                delay = 3,
                                rate = 120,
                                repeat = 2
                            )
                        )
                    )
                ],
            ),        
            pad = (1, 0, 1, 0)
        )
    )

def get_cfg_value(config, key, default):
    value = config.get(key)
    value = json.decode(value) if value else default
    return value    

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "theme",
                name = "Color Theme",
                desc = "Choose the color theme",
                icon = "gear",
                default = "0",
                options = [
                    schema.Option(display = THEME[i]["name"], value = str(i)) for i in range(len(THEME))
                ]
            )
        ]
    )    

THEME = [
    { "name": "Webster", "title": "#FFFFFF", "line": "771122FF", "definition": "#B0B0E0" },
    { "name": "Coast", "title": "#DEEFB7", "line": "6188B9FF", "definition": "#BBBBBB" },
    { "name": "Moss", "title": "#FFFFFF", "line": "414288FF", "definition": "#77AD78" },
    { "name": "Tan", "title": "#D3B88C", "line": "9EBC9FFF", "definition": "#F4F2F3" },
    { "name": "Thistle", "title": "#FFAFF0", "line": "392F5AFF", "definition": "#EEC8E0" },
    { "name": "Maximum Yellow", "title": "#F5F749", "line": "F24236FF", "definition": "#F6F5AE" },
    { "name": "Copper Penny", "title": "#BA6E6E", "line": "A63A50FF", "definition": "#F0E7D8" },
    { "name": "Lavender Web", "title": "#ACB0BD", "line": "416165FF", "definition": "#D0CDD7" },
    { "name": "Orange Red", "title": "#F26430", "line": "11AEEDFF", "definition": "#8983CA" },
    { "name": "Sage", "title": "#BCBD8B", "line": "373D20FF", "definition": "#EFF1ED" },  
    { "name": "Redwood", "title": "#8D5B4C", "line": "5A2A27FF", "definition": "#C4BBAF" }, 
    { "name": "Asparagus", "title": "#88AB75", "line": "DE8F6EFF", "definition": "#FDF78F" },        
    { "name": "Air Superiority Blue", "title": "#769FB6", "line": "1999B3FF", "definition": "#F9F7F1" },            
]

# Custom Marquee "Widget"
#
# Copyright (c) 2022 Paul Osburn
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

def custom_marquee(text, width = 64, height = 32, rate = 100, color = "#fff", font = "tb-8", shadow = False, center = False, delay = 0, default_duration = 6, repeat = 1):
    """
    Returns an array of frames that scrolls the text vertically like a marquee

    Features:
        * Initial delay before marquee starts scrolling
        * Simple drop shadow for text
        * Centering
        * Simple hyphenation support

    The custom marquee requires an animation widget. While this is a requirement for
    the scrolling to work, it also means that you can have a marquee in an animation
    widget. So requirement / feature ... depends on your perspective.

    Args:
      text: The text to display in the marquee
      width: The width of the marquee
      height: The height of the marquee
      rate: The rate at which the marquee will scroll (larger means slower)
      color: The color of the text that displays
      font: The font to use
      shadow: If True a drop shadow is displayed behind the text
      center: If True each line of the text in the marquee is centered
      delay: The delay before the marquee begins scrolling
      default_duration: The default duration of the animation. If not specified the
        duration is calculated based on the above parameters
      repeat: The number of times the animation should be repeated

    Returns:
        Array of widget frames that can be animated

    Note: Only supports vertical scrolling but could be modified to support scrolling 
        in all 4 directions
    """

    wrapped_frames = []

    def font_width(font):
        return FONT_METRICS.get(font.lower(), FONT_METRICS_DEFAULT).get("width", 1)

    def font_height(font):
        return FONT_METRICS.get(font.lower(), FONT_METRICS_DEFAULT).get("height", 1)

    # Returns a tuple: (chars_per_line, lines)
    def font_metrics(text, font, width):    
        txt_width = font_width(font)
        txt_height = font_height(font)

        chars_per_line = width / txt_width
        lines = int((len(text) / chars_per_line) + 0.5)

        # print("%s (%d)" % (text, len(text)))
        # print("cpl = %d, lines = %d" % (chars_per_line, lines))

        return (chars_per_line, lines)

    # Splits text so that it wraps correctly on mulitple lines
    def split(text, width, height, font):
        strings = []

        stats = font_metrics(text, font, width)
        chars_per_line = stats[0]

        # Break the text into separate words
        items = text.split(" ")

        # Adjust for hyphens present
        words = []
        for i in range(len(items)):
            if items[i].count("-") > 0:
                parts = items[i].split("-")
                parts[0] += "-"
                words.extend(parts)
            else:
                words.append(items[i])

        # Break the words up in to lines based on what is possible
        # based on the font
        current_line = ""
        num_items = len(words)
        for i in range(num_items):
            current_len = len(current_line) + 1
            word = words[i].lstrip()
            if current_len + len(word) <= chars_per_line:
                current_line += "%s " % word
                if i == num_items - 1:
                    strings.append(current_line.rstrip())
            else:
                strings.append(current_line.rstrip())
                current_line = "%s " % word
                if i == num_items - 1:
                    strings.append(word.rstrip())

        return strings

    # Calculates the padding required on one side to center the text
    def pad_for_centering(txt, width, font, should_center = True):
        if should_center == False:
            return 0

        txt_len = len(txt)
        txt_width = font_width(font)

        pad = max(0, (width - len(txt) * txt_width) / 2)
        return pad

    # Renders a column of text based on the specified text items
    def render_text_block(items, width, font, color, center):
        return render.Column(
            children = [ 
                render.Padding(
                    pad = (
                        pad_for_centering(items[i], width, font, center), 
                        0, 
                        pad_for_centering(items[i], width, font, center), 
                        0
                    ),
                    child = render.Text(content = items[i], 
                        font = font, 
                        color = color)
                ) for i in range(len(items))
            ]
        )

    # Calculates the number of frames required based on the duration and rate
    def duration(seconds):
        return int((seconds * 1000) / rate)

    # Adds the required number of frames based on the duration
    def frames(f, child, duration):
        for _ in range(duration):
            f.append(child)

        return f

    # Breaks up the text into multiple lines based on the width and the font
    # Returns a stack with the text and a shadow
    def wrapped_text(items, width, height, color, offset, font, has_shadow, center, repeat):
        children = []
        if has_shadow:
            children.append(
                render.Padding(
                    pad = (0, offset + 1, 0, 0),    # Change position of offset for different scrolling
                    child = render_text_block(items, width, font, "#000", center)
                )
            )

        children.append(
            render.Padding(
                pad = (0, offset, 0, 0),    # Change position of offset for different scrolling
                child = render_text_block(items, width, font, color, center)
            
            )
        )

        return render.Stack(
            children = children
        )

    # Determine lines based on the font
    stats = font_metrics(text, font, width)
    lines = stats[1]
    txt_height = font_height(font)
    max_lines = int(height / txt_height)
    
    # Calculate the intial delay if the caller did not specify it
    seconds_per_screen = ((height * rate) / 1000)
    screens = max(1, lines / max_lines) + 1
    if delay == 0:
        delay = seconds_per_screen

    seconds = 0
    items = split(text, width, height, font)

    # Will it fit on 1 screen?
    # print("lines = %d, max_lines = %d" % (lines, max_lines))
    if lines < max_lines:
        seconds = default_duration

        if center == True:
            return frames(
                wrapped_frames,
                render.Box(
                    child = wrapped_text(items, width, height, color, 0, font, shadow, center, repeat)
                ), duration(seconds)
            )

        else:
            return frames(
                wrapped_frames,
                wrapped_text(items, width, height, color, 0, font, shadow, center, repeat)
                , duration(seconds)
            )
    
    # Otherwise scroll

    # Determine how long it will take to scroll through all of the text
    # (including the text going off the screen)
    seconds = seconds_per_screen * screens

    for i in range(repeat):
        wrapped_frames = frames(wrapped_frames, wrapped_text(items, width, height, color, 0, font, shadow, center, repeat), duration(delay))
        for i in range(duration(seconds)):
            wrapped_frames = frames(wrapped_frames, wrapped_text(items, width, height, color, -i, font, shadow, center, repeat), 1)

    # print("Total seconds: %d" % (initial_delay + seconds))
    return wrapped_frames

# These are approximate in the case of variable-width fonts
FONT_METRICS = {
    "tb-8":              { "width": 5, "height": 8 },
    "tom-thumb":         { "width": 4, "height": 6 },
    "dina_r400-6":       { "width": 6, "height": 10 },
    "5x8":               { "width": 5, "height": 8 },
    "6x13":              { "width": 6, "height": 13 },
    "CG-pixel-3x5-mono": { "width": 4, "height": 5 },
    "CG-pixel-4x5-mono": { "width": 5, "height": 5 },
}

FONT_METRICS_DEFAULT = {
    "width": 5,
    "height": 8
}