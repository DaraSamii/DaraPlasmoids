.pragma library

// [text, scene kind, theme icon, cloud count]
const WMO = {
    0: ["Clear sky", "clear", "weather-clear", 0],
    1: ["Mainly clear", "clear", "weather-few-clouds", 1],
    2: ["Partly cloudy", "cloudy", "weather-clouds", 3],
    3: ["Overcast", "cloudy", "weather-overcast", 5],
    45: ["Fog", "fog", "weather-fog", 5], 48: ["Rime fog", "fog", "weather-fog", 5],
    51: ["Light drizzle", "rain", "weather-showers-scattered", 5], 53: ["Drizzle", "rain", "weather-showers-scattered", 5],
    55: ["Heavy drizzle", "rain", "weather-showers", 5],
    56: ["Freezing drizzle", "rain", "weather-freezing-rain", 5], 57: ["Freezing drizzle", "rain", "weather-freezing-rain", 5],
    61: ["Light rain", "rain", "weather-showers-scattered", 5], 63: ["Rain", "rain", "weather-showers", 5],
    65: ["Heavy rain", "rain", "weather-showers", 5],
    66: ["Freezing rain", "rain", "weather-freezing-rain", 5], 67: ["Freezing rain", "rain", "weather-freezing-rain", 5],
    71: ["Light snow", "snow", "weather-snow-scattered", 5], 73: ["Snow", "snow", "weather-snow", 5],
    75: ["Heavy snow", "snow", "weather-snow", 5], 77: ["Snow grains", "snow", "weather-snow", 5],
    80: ["Light showers", "rain", "weather-showers-scattered", 5], 81: ["Showers", "rain", "weather-showers", 5],
    82: ["Violent showers", "rain", "weather-showers", 5],
    85: ["Snow showers", "snow", "weather-snow-scattered", 5], 86: ["Heavy snow showers", "snow", "weather-snow", 5],
    95: ["Thunderstorm", "storm", "weather-storm", 5], 96: ["Thunderstorm with hail", "storm", "weather-storm", 5],
    99: ["Thunderstorm with hail", "storm", "weather-storm", 5]
};
// icons that ship a "-night" variant in Breeze
const HAS_NIGHT = ["weather-clear", "weather-few-clouds", "weather-clouds", "weather-showers-scattered",
                   "weather-showers", "weather-snow-scattered", "weather-snow", "weather-storm"];

function info(code, isDay) {
    const w = WMO[code] || ["Unknown", "cloudy", "weather-none-available", 5];
    const night = !isDay && HAS_NIGHT.indexOf(w[2]) >= 0;
    return { text: w[0], kind: w[1], icon: night ? w[2] + "-night" : w[2], clouds: w[3] };
}

const pad = n => (n < 10 ? "0" : "") + n;
const hourOf = iso => +iso.substr(11, 2);
function mins(iso) { return hourOf(iso) * 60 + +iso.substr(14, 2); }
function hourLabel(iso, h24) {
    const h = hourOf(iso);
    return h24 ? pad(h) : ((h % 12) || 12) + " " + (h < 12 ? "AM" : "PM");
}
function timeLabel(iso, h24) {
    const h = hourOf(iso), m = iso.substr(14, 2);
    return h24 ? pad(h) + ":" + m : ((h % 12) || 12) + ":" + m + " " + (h < 12 ? "AM" : "PM");
}
function dayName(iso, i) {
    if (i === 0) return "Today";
    const d = new Date(+iso.substr(0, 4), +iso.substr(5, 2) - 1, +iso.substr(8, 2));
    return Qt.locale().dayName(d.getDay(), 1); // 1 = QLocale::ShortFormat
}
function duration(a, b) { const m = mins(b) - mins(a); return Math.floor(m / 60) + "h " + pad(m % 60) + "m"; }
function compass(deg) { return ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][Math.round(deg / 45) % 8]; }
function uvLabel(u) { return u < 3 ? "Low" : u < 6 ? "Moderate" : u < 8 ? "High" : u < 11 ? "Very high" : "Extreme"; }

// ---- places (stored as JSON in the applet config) ----
function parsePlaces(s) {
    try { const a = JSON.parse(s); return Array.isArray(a) ? a : []; } catch (e) { return []; }
}
function placeLabel(p) { return [p.name, p.admin1, p.country].filter(Boolean).join(", "); }
function addPlace(s, p) {
    const a = parsePlaces(s);
    let i = a.findIndex(x => Math.abs(x.lat - p.lat) < 0.01 && Math.abs(x.lon - p.lon) < 0.01);
    if (i < 0) { a.push(p); i = a.length - 1; }
    return { json: JSON.stringify(a), index: i };
}
function removePlace(s, i) { // never removes the last place
    const a = parsePlaces(s);
    if (a.length > 1) a.splice(i, 1);
    return JSON.stringify(a);
}

// ---- Open-Meteo ----
// [key, label] — all served by Open-Meteo, which blends national weather-service models
const MODELS = [
    ["best_match", "Best match (automatic)"], ["gem_seamless", "GEM — Environment Canada"],
    ["ecmwf_ifs025", "ECMWF IFS — Europe"], ["gfs_seamless", "GFS — NOAA (USA)"],
    ["icon_seamless", "ICON — DWD (Germany)"], ["meteofrance_seamless", "Météo-France"],
    ["jma_seamless", "JMA — Japan"]
];
// [key, label, url template] — where "open forecast online" goes
const SITES = [
    ["windy", "Windy", "https://www.windy.com/{lat}/{lon}?{lat},{lon},8"],
    ["yr", "Yr (MET Norway)", "https://www.yr.no/en/forecast/daily-table/{lat},{lon}"],
    ["openmeteo", "Open-Meteo", "https://open-meteo.com/en/docs?latitude={lat}&longitude={lon}"],
    ["google", "Google Weather", "https://www.google.com/search?q=weather+{name}"]
];
function modelLabel(key) { const m = MODELS.find(x => x[0] === key); return m ? m[1] : key; }
function siteLabel(key) { return (SITES.find(x => x[0] === key) || SITES[0])[1]; }
function siteUrl(key, p) {
    return (SITES.find(x => x[0] === key) || SITES[0])[2].split("{lat}").join(p.lat).split("{lon}").join(p.lon)
        .split("{name}").join(encodeURIComponent(p.name));
}
// null-safe number formatting: models differ in what they provide
function num(v, d) { return v === null || v === undefined ? "–" : (d ? (+v).toFixed(d) : Math.round(v)); }

function forecastUrl(p, imperial, model) {
    return "https://api.open-meteo.com/v1/forecast?latitude=" + p.lat + "&longitude=" + p.lon
        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,is_day,precipitation,weather_code,cloud_cover,pressure_msl,wind_speed_10m,wind_direction_10m,wind_gusts_10m"
        + "&hourly=temperature_2m,precipitation_probability,weather_code,is_day,visibility,uv_index"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max,precipitation_sum"
        + "&timezone=auto&forecast_days=7&temperature_unit=" + (imperial ? "fahrenheit" : "celsius")
        + "&wind_speed_unit=" + (imperial ? "mph" : "kmh") + "&precipitation_unit=" + (imperial ? "inch" : "mm")
        + (model && model !== "best_match" ? "&models=" + model : "");
}

// Open-Meteo times are location-local ISO strings; we never convert them, only slice.
function normalize(r) {
    const c = r.current, h = r.hourly, d = r.daily;
    let i = h.time.findIndex(t => t.substr(0, 13) === c.time.substr(0, 13));
    if (i < 0) i = 0;
    const hours = [];
    for (let k = i; k < Math.min(i + 24, h.time.length); k++)
        hours.push(Object.assign({ time: h.time[k], temp: h.temperature_2m[k], pop: h.precipitation_probability[k] || 0 },
                                 info(h.weather_code[k], h.is_day[k])));
    const days = d.time.map((t, k) => Object.assign({
        date: t, max: d.temperature_2m_max[k], min: d.temperature_2m_min[k], pop: d.precipitation_probability_max[k] || 0,
        sunrise: d.sunrise[k], sunset: d.sunset[k], uv: d.uv_index_max[k], precip: d.precipitation_sum[k]
    }, info(d.weather_code[k], 1)));
    const now = Object.assign({}, c, info(c.weather_code, c.is_day), { visibility: h.visibility[i], uv: h.uv_index[i] });
    return { now: now, hours: hours, days: days, units: r.current_units };
}
