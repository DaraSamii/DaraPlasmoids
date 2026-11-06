# DaraPlasmoids

Custom widgets for **KDE Plasma 6**.

## Dara Weather

A detailed, animated weather widget for your panel. Add one per city (e.g. Montreal and Tehran) — each instance keeps its own place list and settings.

![Dara Weather](docs/screenshot.png)

### Features

- **Glass look**: the sky scene fills the popup, is blurred under the content, and every section is a frosted-glass card (tint adjustable, plain Plasma-theme fallback available).
- **Panel icon + temperature**, optional city name and unit letter. Tooltip shows condition and high/low. Click to open the popup.
- **Animated hero scene** that follows the weather and time of day: sun with rotating rays, moon and twinkling stars, drifting clouds, rain, snow, fog and lightning.
- **Plain-language summary**: "Rain expected around 3 p.m.", "Dry for the next 12 hours", or how much wind/humidity changes the feel.
- **Next 12 / 24 / 48 hours**: scrollable strip with icons, a smooth temperature curve that draws itself in, and precipitation chance (Shift + wheel or drag to scroll sideways). Times read `2 a.m.`, `3 p.m.` (or 24-hour).
- **3–7 day forecast** with animated high/low range bars.
- **Sun arc**: bold colored sunrise and sunset times, daylight length, and a pulsing sun showing where it is now.
- **Visual details**: wind card (compass arrow, streaks that blow faster with stronger wind, gusts), humidity as a filling water droplet, rain drops for precipitation, colored gauges for UV, pressure, visibility and cloud cover.
- **Multiple places**: switch with chips in the popup, add with **+** (city search), remove with the trash button on the selected chip.
- **Sources**: forecast model (Best match, GEM – Environment Canada, ECMWF, GFS, ICON, Météo-France, JMA) and the website opened by the globe button (Windy, Yr, Open-Meteo, Google Weather).
- **Offline notice**: if a refresh fails you keep the last data with an "Offline — showing data from …" line.
- Uses your Plasma theme icons and fonts; animations stop automatically if you disable Plasma animations.

### Settings

Grouped into six pages:

| Page | What you can change |
|---|---|
| **Places** | Saved cities for this widget, current city, city search |
| **Units & Time** | Temperature (°C/°F), wind (km/h, mph, m/s, kn), pressure (hPa, inHg, mmHg), precipitation (mm/in), 12/24-hour clock, refresh interval |
| **Sources** | Forecast model, website opened by the globe button |
| **Appearance** | Glass with blur / Glass / Plain, glass tint, animations on/off, popup size |
| **Panel** | Icon, temperature, city name, unit letter |
| **Content** | Summary, hourly (12/24/48 h), daily (3–7 days), sun, and each detail card |

### Design notes

Informed by common weather-app UX guidance and glassmorphism accessibility advice: now → next hours → days ordering, a one-line "so what?" summary, icons that are recognizable at a glance, secondary metrics below the fold (and hideable), a contrast scrim under the glass so text stays readable on bright skies, a solid *Plain* fallback, and reduced motion following the system setting.

### Install

Requires Plasma 6 (tested on 6.7) and internet access.

```sh
git clone https://github.com/DaraSamii/DaraPlasmoids.git
cd DaraPlasmoids
./install.sh          # kpackagetool6 install/upgrade for your user
```

Then right-click the panel → **Add Widgets…** → search **Dara Weather**. If it doesn't appear, run `kquitapp6 plasmashell; kstart plasmashell`.

Try it without adding to a panel: `plasmawindowed io.github.darasamii.weather`.

Uninstall: `kpackagetool6 -t Plasma/Applet -r io.github.darasamii.weather`.

### One widget per city

1. Add the widget to a panel and open its settings (right-click → *Configure*, or the gear in the popup).
2. Search and add your city (e.g. *Montreal*), select it as the current place.
3. Add a second widget (to another panel or the same one) and select *Tehran*.

Each widget stores its own list and selection, so they never interfere.

### Data

Forecast and geocoding come from [Open-Meteo](https://open-meteo.com) — free, no API key, non-commercial use. Open-Meteo blends national weather-service models; the *Forecast model* setting picks which one. Some models don't provide UV, visibility, gusts or rain chance — those show as `–`. Times are shown in the city's local time.

### Layout

```
weather/
  metadata.json
  contents/
    config/      main.xml (settings schema), config.qml
    code/        weather.js (WMO codes, formatting, Open-Meteo requests)
    ui/          main.qml, Compact/FullRepresentation, WeatherScene,
                 HourlyChart, DayRow, SunArc, Tile, Card, PlaceSearch, configGeneral
```

### Known limits

- Condition names are English only (UI strings are translatable via `i18n`, no translations shipped yet).
- Data is kept in memory only; with no network at startup the popup shows an error until the next refresh.
- Hourly chart shows 24 h; daily shows 7 days.

### License

MIT — see [LICENSE](LICENSE).
