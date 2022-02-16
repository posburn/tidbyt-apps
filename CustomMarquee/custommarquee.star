"""
Applet: Custom Marquee
Summary: Sample App
Description: Displays a long string of text in a custom marquee
Author: posburn
"""

load("render.star", "render")
load("schema.star", "schema")

def main(config):
    sample = "Good thing the body doesn't contain any of this second-lightest gas, otherwise you might float away"
    rate = 100

    return render.Root(
        delay = rate,
        child = render.Stack(
            children = [
                # Background
                render.Box(color = "#226644"),

                # Simple call
                render.Animation(custom_marquee(sample))

                # All parameters
                # render.Animation(
                #     custom_marquee(
                #         text = sample,
                #         width = 64,
                #         height = 32,
                #         rate = 100,
                #         color = "#FFF",
                #         font = "tom-thumb",
                #         shadow = True,
                #         center = True,
                #         delay = 4,
                #         default_duration = 5
                #     )
                # )

                # With padding
                # render.Padding(pad = (0, 12, 0, 0),
                #     child = render.Animation(custom_marquee(sample, height = 20)) # 32 - 12 = 20
                # )
            ]
        )
    )    

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

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