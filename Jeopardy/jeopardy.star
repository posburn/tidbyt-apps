"""
Applet: Jeopardy
Summary: Play Jeopardy
Description: Displays the category, an answer and then the correct question in Jeopardy style.
Author: posburn
"""

load("render.star", "render")
load("schema.star", "schema")
load("cache.star", "cache")
load("http.star", "http")
load("encoding/json.star", "json")

# Jeopardy Tidbyt App
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

def main(config):
    """ 
    Play Jeopardy on your Tidbyt, one answer at a time

    Displays the category, an answer and then the correct question 
    in Jeopardy style.

    Args:
        config: This is config data

    Returns:
        The widget(s) that represent the application's UI
    """

    # - DATA

    category = "?"
    answer = ""
    question = ""
    complete_question = ""
    value = "$"

    # Returns a tuple: (data, was_cached)
    def fetch_data(url, params, cache_key):
        # Check cache first
        cached_data = cache.get(cache_key)

        if cached_data != None:
            # Use what's in the cache
            print("Found cached data")
            return (cached_data, True)

        else:
            print("Cache miss")
            rep = http.get(url)
            if rep.status_code != 200:
                print("Request failed with status %d" % rep.status_code)
                return ""

            return (rep.json(), False)

    def clean_text(txt):
        txt = txt.replace("<i>", "").replace("</i>", "")
        txt = txt.replace("\"", "").replace("</i>", "")
        return txt

    def render_category():
        return custom_marquee(
            text = category,
            color = MAIN_TEXT,
            font = SMALL_FONT,
            shadow = True,
            center = True,
            delay = 2,
            default_duration = 2)

    def render_value():
        return custom_marquee(
            text = value,
            color = HIGHLIGHTED_TEXT,
            font = HIGHLIGHTED_FONT,
            shadow = True,
            center = True,
            delay = 2,
            default_duration = 2)

    def render_answer():
        return custom_marquee(
            text = answer, 
            color = MAIN_TEXT, 
            font = SMALL_FONT,
            shadow = True,
            center = True,
            delay = 4)

    def render_question():
        return custom_marquee(
            text = complete_question, 
            color = MAIN_TEXT, 
            font = SMALL_FONT,
            shadow = True,
            center = True,
            delay = 3,
            default_duration = 3)

    def countdown_color(total, on, item):
        on_color = "#B00"
        off_color = "#100"

        if on <= 0:
            return off_color

        remove_count_per_side = int((total - on) // 2)
        center = (total - 1) // 2

        # From the beginning
        if item < center and item < remove_count_per_side:
            return off_color

        # From the end
        if item > center and item > total - remove_count_per_side - 1:
            return off_color

        return on_color

    def render_countdown(total, on):
        # items should be an odd number
        if total % 2 == 0:
            total -= 1
        items = total * 2 - 1
        
        on = on * 2 - 1
        width = int(64 / items) - 1
        countdown_width = min(64, width * items + items)
        pad = max(0, (64 - countdown_width) // 2)
        
        return render.Padding(
            pad = (pad, 0, pad, 0),
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Padding( # Question marks + shadow
                        pad = (0, 8, 0, 9),
                        child = render.Stack(
                            children = [
                                render.Padding(pad = (0, 1, 0, 0), child = render.Text(content = "???", color = SHADOW_TEXT, font = MAIN_FONT)),
                                render.Text(content = "???", color = MAIN_TEXT, font = MAIN_FONT)
                            ]
                        )
                    ),
                    render.Stack(   # Countdown items
                        children = [
                            render.Box(width = 64, height = 6, color = "#111"),
                            render.Row(
                                children = [
                                    render.Stack(
                                        children = [
                                            render.Padding(
                                                pad = (0, 1, 1, 0), 
                                                child = render.Box(
                                                    width = width, 
                                                    height = 4, 
                                                    color = countdown_color(items, on, i)
                                                )
                                            ),
                                        ]
                                    ) for i in range(items)
                                ]
                            )
                        ]
                    )
                ]
            )
        )

    # Calculates the number of frames required based on the duration and rate
    rate = 100 

    # Calculates the number of frames required based on the duration and rate
    def duration(seconds):
        return int((seconds * 1000) // rate)

    # Adds the required number of frames based on the duration
    def frames(f, child, duration):
        for _ in range(duration):
            f.append(child)

        return f

    # Builds the frames that make up the UI
    def render_frames():
        fr = []
        fr.extend(render_category())
        fr.extend(render_value())
        fr.extend(render_answer())

        countdown_items = 3
        for i in range(countdown_items):
            fr = frames(fr, render_countdown(countdown_items, countdown_items - i), duration(1))   
                                
        fr.extend(render_question())
        return fr        

    # - MAIN APP
    
    data = fetch_data(URL, {}, CACHE_KEY_DATA)  # [0] = data, [1] = was_cached

    if len(data) != 2:
        print("Data in incorrect format or missing")

    elif data[1] == False:
        item = data[0][0]
        
        category_data = item.get("category", {})
        category = category_data.get("title", "").title()
        
        amount = item.get("value", 0)
        if amount == None:
            value = "$0"
        else:
            value = "$%d" % amount

        answer = item.get("question", "")
        question = item.get("answer", "")
        prefix = "What is "

        complete_question = prefix + question + "?"

        answer = clean_text(answer)
        question = clean_text(question)

        item_dict = {
            "category": category,
            "value": value,
            "answer": answer,
            "question": complete_question
        }

        item_cached = json.encode(item_dict)
        cache.set(CACHE_KEY_DATA, item_cached, ttl_seconds=300) # Cache expires in 5 minutes
    else:
        content = json.decode(data[0])
        category = content.get("category", "")
        value = content.get("value", "")
        answer = content.get("answer", "")
        complete_question = content.get("question", "")

    return render.Root(
        delay = rate,
        child = render.Stack(
            children = [
                render.Box(color = BLUE_BACKGROUND),
                render.Animation(children = render_frames())
            ]
        )
    )

# - CONFIG

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

# - CONSTANTS

URL = "https://jservice.io/api/random?count=1"
CACHE_KEY_DATA = "saved_data"

# Styles
BLUE_BACKGROUND = "#0C0F8A"
MAIN_TEXT = "#FFF"
SHADOW_TEXT = "#000"
HIGHLIGHTED_TEXT = "#D69F4C"
MAIN_FONT = "tb-8"
SMALL_FONT = "tom-thumb"
HIGHLIGHTED_FONT = "Dina_r400-6"

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

def custom_marquee(text, width = 64, height = 32, rate = 100, color = "#fff", font = "tb-8", shadow = False, center = False, delay = 0, default_duration = 6):
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

        chars_per_line = width // txt_width
        lines = len(text) // chars_per_line

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

        pad = max(0, (width - len(txt) * txt_width) // 2)
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
        return int((seconds * 1000) // rate)

    # Adds the required number of frames based on the duration
    def frames(f, child, duration):
        for _ in range(duration):
            f.append(child)

        return f

    # Breaks up the text into multiple lines based on the width and the font
    # Returns a stack with the text and a shadow
    def wrapped_text(items, width, height, color, offset, font, has_shadow, center):
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
    max_lines = int(height // txt_height)
    
    # Calculate the intial delay if the caller did not specify it
    seconds_per_screen = ((height * rate) // 1000)
    screens = max(1, lines // max_lines) + 1
    if delay == 0:
        delay = seconds_per_screen

    seconds = 0
    items = split(text, width, height, font)

    # Will it fit on 1 screen?
    if lines < max_lines:
        seconds = default_duration

        if center == True:
            return frames(
                wrapped_frames,
                render.Box(
                    child = wrapped_text(items, width, height, color, 0, font, shadow, center)
                ), duration(seconds)
            )

        else:
            return frames(
                wrapped_frames,
                wrapped_text(items, width, height, color, 0, font, shadow, center)
                , duration(seconds)
            )
    
    # Otherwise scroll

    # Determine how long it will take to scroll through all of the text
    # (including the text going off the screen)
    seconds = seconds_per_screen * screens + 1

    wrapped_frames = frames(wrapped_frames, wrapped_text(items, width, height, color, 0, font, shadow, center), duration(delay))
    for i in range(duration(seconds)):
        wrapped_frames = frames(wrapped_frames, wrapped_text(items, width, height, color, -i, font, shadow, center), 1)

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