# Liquid Glass (Home Assistant)

A dark frosted-glass Rainmeter widget for Home Assistant. It shows the current time, weather, selected lights, and media players in a compact desktop panel.

## Requirements

- Rainmeter 4.5+
- Home Assistant instance reachable from this PC
- `HomeAssitantPlugin.dll` in your `Documents\Rainmeter\Plugins\` folder

## Setup

1. Copy the `LiquidGlass` folder into your `Documents\Rainmeter\Skins\` folder.
2. Ensure `@Resources\Settings.inc` matches your HA connection and entities.
3. Refresh the skin in Rainmeter.

## Restoring from this repo

`@Resources/Settings.inc`, `ha-control.js`, and `ha-control.ps1` hold your
Home Assistant server, token, and entity IDs and are gitignored, and
`states.md` is a live entity-state dump. The repo tracks `.example` copies
with placeholders. After cloning:

1. Copy each `.example` file to its real name in `@Resources\`.
2. Set `HA_SERVER` and `PLUGIN_PATH`, paste your HA long-lived access
   token into all three files, and set the `ENTITY_*` IDs to match
   your instance.
3. Refresh the skin in Rainmeter.

## Configuration

Main settings live in `@Resources/Settings.inc`:

- `HA_SERVER`, `HA_TOKEN`, `HA_SSL`, `HA_PORT`
- `WEATHER_ENTITY`, `CLIMATE_ENTITY`, `LIGHT_ENTITY`, `PRESENCE_ENTITY`, `SENSOR_ENTITY`
- Labels and units: `LOCATION_LABEL`, `LIGHT_LABEL`, `UNIT_TEMP`, `UNIT_WIND`, `UNIT_PRESS`

The full HA entity list is also defined in `Settings.inc` for reuse across measures.

## Device Control

Click any **light tile** to toggle it on/off.
Click any **media tile** to play/pause.

Control is handled by `@Resources/ha-control.js`, which calls the Home Assistant REST API using Windows Script Host (`cscript.exe`). This avoids PowerShell execution-policy issues.

## Layout

| Section | Top Y | Height | Notes |
|---------|-------|--------|-------|
| Panel | 0 | 624 | Background shape + noise texture |
| Clock/Date | 62 | 130 | Time + day/date |
| Weather | 168 | 130 | Icon, temp, condition, H/L |
| Lights | 285 | 160 | 2×2 grid |
| Media | 435 | 160 | 2×2 grid |
| Footer | 582 | 20 | Label + live status |

## Notes

- Rainmeter 4.5 Shape meters use `Fill Color R,G,B` and `Stroke Color R,G,B`.
- `LinearGradient`, `Polygon`, and float alpha values are not supported in this build.
- If the panel uses `noise.png`, place it in `@Resources\`.

## Files

- `LiquidGlass.ini` — skin measures and meters
- `@Resources/Settings.inc` — connection, entities, and labels
- `@Resources/ha-control.js` — JScript helper for HA service calls (toggle lights, play/pause media)
- `@Resources/noise.png` — optional grain texture
- `STRUCTURE.md` — detailed file and section map
- `BANK.md` — debugging history and known issues
