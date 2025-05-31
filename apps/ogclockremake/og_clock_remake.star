"""
Applet: OG Clock Remake
Summary: OG Clock Remake
Description: A remake of the original Tidbyt Clock App (Reddit initiative).
Author: bendiep + Josiah Winslow

TODO:
- Get more weather icons

NOTE:
- "weatherCode" corresponds to codes from this API: https://www.worldweatheronline.com/weather-api/api/docs/weather-icons.aspx
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = """
{
    "lat": "40.6781784",
    "lng": "-73.9441579",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/New_York"
}
"""
DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_TIME_COLOR = "#FFF"
UNIT_NAMES = {
    "f": "temp_F",
    "c": "temp_C",
}

TTL_SECONDS = 60  # 1 minute

INFO_COLOR = "#FFF"
HUMIDITY_COLOR = "#66F"

PLACEHOLDER_WEATHER_DATA = {
    "current_condition": {
        "humidity": "97",
        "temp_C": "12",
        "temp_F": "54",
        "weatherCode": "296",
    },
}

PLACEHOLDER_WEATHER_ICON = base64.decode("""
UklGRvQCAABXRUJQVlA4WAoAAAAwAAAADAAADAAASUNDUKACAAAAAAKgbGNtcwRAAABtbnRyUkdCIFh
ZWiAH6QAFAB0ACgATAANhY3NwTVNGVAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA9tYAAQAAAADTLW
xjbXMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1kZXNjAAABI
AAAAEBjcHJ0AAABYAAAADZ3dHB0AAABmAAAABRjaGFkAAABrAAAACxyWFlaAAAB2AAAABRiWFlaAAAB
7AAAABRnWFlaAAACAAAAABRyVFJDAAACFAAAACBnVFJDAAACFAAAACBiVFJDAAACFAAAACBjaHJtAAA
CNAAAACRkbW5kAAACWAAAACRkbWRkAAACfAAAACRtbHVjAAAAAAAAAAEAAAAMZW5VUwAAACQAAAAcAE
cASQBNAFAAIABiAHUAaQBsAHQALQBpAG4AIABzAFIARwBCbWx1YwAAAAAAAAABAAAADGVuVVMAAAAaA
AAAHABQAHUAYgBsAGkAYwAgAEQAbwBtAGEAaQBuAABYWVogAAAAAAAA9tYAAQAAAADTLXNmMzIAAAAA
AAEMQgAABd7///MlAAAHkwAA/ZD///uh///9ogAAA9wAAMBuWFlaIAAAAAAAAG+gAAA49QAAA5BYWVo
gAAAAAAAAJJ8AAA+EAAC2xFhZWiAAAAAAAABilwAAt4cAABjZcGFyYQAAAAAAAwAAAAJmZgAA8qcAAA
1ZAAAT0AAACltjaHJtAAAAAAADAAAAAKPXAABUfAAATM0AAJmaAAAmZwAAD1xtbHVjAAAAAAAAAAEAA
AAMZW5VUwAAAAgAAAAcAEcASQBNAFBtbHVjAAAAAAAAAAEAAAAMZW5VUwAAAAgAAAAcAHMAUgBHAEJW
UDhMLgAAAC8MAAMQDzD/8z//8x/wUNRIktK7x3/UczllpxRFRfQ/YNPNt9lpWnFEa6ftZgM=
""")

def get_weather(location):
    weather = PLACEHOLDER_WEATHER_DATA

    # Source of weather information is wttr.in
    url = "http://wttr.in/%s,%s?format=j1" % (location["lat"], location["lng"])
    rep = http.get(url, ttl_seconds = TTL_SECONDS)
    if rep.status_code == 200:
        weather = rep.json()

    return weather["current_condition"][0]

def main(config):
    # Get location and timezone
    location = json.decode(config.get("location", DEFAULT_LOCATION))
    timezone = location.get("timezone", config.get("$tz", DEFAULT_TIMEZONE))

    # Get more config options
    time_color = config.get("time_color", DEFAULT_TIME_COLOR)
    use_24hclock = config.bool("24hclock", False)
    blink = config.bool("blink", True)
    unit = config.str("unit", "f")
    display_location = config.bool("display_location", False)
    display_weather = config.bool("display_weather", True)

    # Get current time
    now = time.now().in_location(timezone)

    # Render time
    time_format = "03:04" if use_24hclock else "3:04 PM"
    time_format_blink = time_format
    if blink:
        time_format_blink = time_format_blink.replace(":", " ")
    text_time = render.Text(
        content = now.format(time_format),
        font = "6x13",
        color = time_color,
        height = 11,
        offset = -1,
    )
    text_time_blink = render.Text(
        content = now.format(time_format_blink),
        font = "6x13",
        color = time_color,
        height = 11,
        offset = -1,
    )
    component_time = render.Animation(
        children = [text_time] * 4 + [text_time_blink] * 4,
    )

    # Render location
    component_location = None
    if display_location:
        component_location = render.Marquee(
            width = 64,
            align = "center",
            child = render.Text(
                content = location["locality"],
                font = "5x8",
                color = INFO_COLOR,
                height = 7,
            ),
        )

    # Render weather
    unit_name = UNIT_NAMES[unit]
    component_weather = None
    if display_weather:
        weather = get_weather(location)
        component_weather = render.Row(
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (0, 0, 1, 0),
                    child = render.Image(src = PLACEHOLDER_WEATHER_ICON),
                ),
                render.Column(
                    children = [
                        render.Text(
                            content = weather[unit_name],
                            font = "5x8",
                            color = INFO_COLOR,
                            height = 7,
                        ),
                        render.Text(
                            content = "%s%%" % weather["humidity"],
                            font = "5x8",
                            color = HUMIDITY_COLOR,
                            height = 7,
                        ),
                    ],
                ),
            ],
        )

    return render.Root(
        delay = 125,
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    component_time,
                    component_weather,
                    component_location,
                ],
            ),
        ),
    )

def get_schema():
    options_unit = [
        schema.Option(
            display = "Fahrenheit",
            value = "f",
        ),
        schema.Option(
            display = "Celsius",
            value = "c",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display time.",
                icon = "locationArrow",
            ),
            schema.Toggle(
                id = "display_location",
                name = "Display location",
                desc = "Show location in addition to time.",
                icon = "locationDot",
                default = False,
            ),
            schema.Toggle(
                id = "24hclock",
                name = "24 hour clock",
                desc = "Use 24 hour time format.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "display_weather",
                name = "Display weather",
                desc = "Show weather information in addition to time.",
                icon = "cloud",
                default = True,
            ),
            schema.Dropdown(
                id = "unit",
                name = "Temperature units",
                desc = "Preferred units for temperature information.",
                icon = "temperatureHalf",
                default = options_unit[0].value,
                options = options_unit,
            ),
            schema.Color(
                id = "time_color",
                name = "Time color",
                desc = "Color of the time component.",
                icon = "brush",
                default = DEFAULT_TIME_COLOR,
            ),
            schema.Toggle(
                id = "blink",
                name = "Blinking separator",
                desc = "Make the hour-minute separator blink.",
                icon = "gear",
                default = True,
            ),
        ],
    )
