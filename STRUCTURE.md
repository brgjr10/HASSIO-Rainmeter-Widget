# Liquid Glass — Structure

## File tree

```
LiquidGlass/
├── LiquidGlass.ini
├── README.md
├── STRUCTURE.md
├── BANK.md
└── @Resources/
    ├── Settings.inc
    └── noise.png
```

## `LiquidGlass.ini` sections

### Header
- `@include=#@#Settings.inc`
- `[Variables]` — HA connection, primary entities, labels, units, plugin path
- Metadata: `Name`, `Author`, `Information`, `Version`
- Layout constants: `W=380`, `H=980`
- Palette: `C_TEXT`, `C_MUTED`, `C_ACCENT`, `C_SUCCESS`, `C_WARN`, `C_DANGER`

### Measures — Clock
- `[MeasureTime]` — `Format=%H:%M`
- `[MeasureDate]` — `Format=%A, %B %d`

### Measures — Weather
- `[MeasureWxState]` — `state`
- `[MeasureWxTemp]` — `attributes.temperature`
- `[MeasureWxHum]` — `attributes.humidity`
- `[MeasureWxPress]` — `attributes.pressure`
- `[MeasureWxWind]` — `attributes.wind_speed`
- `[MeasureWxBearing]` — `attributes.wind_bearing`
- Commented out: `[MeasureWxHi]`, `[MeasureWxLo]` — forecast path returns null
- Derived: `[MeasureWindDir]` — bearing to compass text

### Measures — Primary entities
- `[MeasureClimateState]` — lightstrip state
- `[MeasureClimateTemp]` — lightstrip brightness
- `[MeasureLightState]` — living room lamp state
- `[MeasurePresence]` — Brodie TV state
- `[MeasureSensor]` — Dane state

### Measures — All HA entities
Full entity index from `Settings.inc`. Includes:
- Binary sensors, buttons, conversations, device trackers, events
- Lights (bedroom, lightstrip, living room, smart plug)
- Media players (Amy, basement, Brodie TV/displays/speakers, Dane, kitchen)
- Notify, numbers, person, select, sensors (backup, iPad, sun)
- Sun, switch, todo, TTS, weather, zone

### Meters — Panel
- `[MeterPanel]` — main background rectangle + edge lines
- `[MeterNoise]` — optional `noise.png` texture

### Meters — Header
- `[MeterDot]` — HA status dot
- `[MeterTitle]` — location label
- `[MeterServer]` — HA server IP
- `[MeterClock]` — large time
- `[MeterDate]` — day/date string
- `[MeterDiv1]` — divider

### Meters — Weather
- `[MeterWxIcon]` — emoji weather icon
- `[MeterWxTemp]` — current temp
- `[MeterWxCond]` — condition text
- `[MeterWxHiLo]` — high/low placeholders
- `[MeterDivWx]` — divider

### Meters — Lights
- `[MeterSectionLights]` — section label
- `[MeterLight1Tile]` + label + state — String Lights
- `[MeterLight2Tile]` + label + state — Brodie's Lightstrip
- `[MeterLight3Tile]` + label + state — Living Room Lamp
- `[MeterLight4Tile]` + label + state — Bedroom Lamp
- `[MeterDivLights]` — divider

### Meters — Media
- `[MeterSectionMedia]` — section label
- `[MeterMedia1Tile]` + label + state — Brodie TV 2
- `[MeterMedia2Tile]` + label + state — Brodie TV
- `[MeterMedia3Tile]` + label + state — Home Display
- `[MeterMedia4Tile]` + label + state — Home Speaker
- `[MeterDivMedia]` — divider

### Meters — Footer
- `[MeterFooterL]` — "Home Assistant · Liquid Glass"
- `[MeterFooterR]` — "live"

## `@Resources/Settings.inc`

- HA connection block
- Primary entity IDs block
- Labels block
- Units block
- `SENSOR_MAX` scale
- Full entity ID list for all HA domains used in the skin

## Coordinate map

| Meter | X | Y | W | H |
|-------|---|---|---|---|
| MeterPanel | 0 | 0 | 380 | 624 |
| MeterDot | 38 | 44 | — | — |
| MeterTitle | 54 | 34 | — | — |
| MeterServer | 350 | 36 | — | — |
| MeterClock | 190 | 62 | — | — |
| MeterDate | 190 | 130 | — | — |
| MeterWxIcon | 34 | 178 | — | — |
| MeterWxTemp | 102 | 170 | — | — |
| MeterWxCond | 34 | 232 | — | — |
| MeterWxHiLo | 34 | 252 | — | — |
| MeterSectionLights | 34 | 285 | — | — |
| Light tiles | 30/196 | 305/365 | 154 | 52 |
| MeterSectionMedia | 34 | 435 | — | — |
| Media tiles | 30/196 | 455/515 | 154 | 52 |
| Footer | 30/350 | 585/582 | — | — |
