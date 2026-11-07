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
    const icon = night ? w[2] + "-night" : w[2];
    // dark cloud icons vanish on dark glass: those use the light symbolic variant (QML picks via `mono`)
    return { text: w[0], kind: w[1], icon: icon, symbolic: icon + "-symbolic", mono: ["weather-clear", "weather-few-clouds", "weather-clouds"].indexOf(w[2]) < 0, clouds: w[3] };
}

const pad = n => (n < 10 ? "0" : "") + n;
const hourOf = iso => +iso.substr(11, 2);
function mins(iso) { return hourOf(iso) * 60 + +iso.substr(14, 2); }
function hourLabel(iso, h24) {
    const h = hourOf(iso);
    return h24 ? pad(h) : ((h % 12) || 12) + " " + (h < 12 ? "a.m." : "p.m.");
}
function timeLabel(iso, h24) {
    const h = hourOf(iso), m = iso.substr(14, 2);
    return h24 ? pad(h) + ":" + m : ((h % 12) || 12) + ":" + m + " " + (h < 12 ? "a.m." : "p.m.");
}
function dayName(iso, i) {
    if (i === 0) return "Today";
    const d = new Date(+iso.substr(0, 4), +iso.substr(5, 2) - 1, +iso.substr(8, 2));
    return Qt.locale().dayName(d.getDay(), 1); // 1 = QLocale::ShortFormat
}
function dateShort(iso) { // "Nov 7"
    return Qt.locale().monthName(+iso.substr(5, 2) - 1, 1) + " " + (+iso.substr(8, 2));
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

const UNITS = {
    temp: [["°C", "celsius"], ["°F", "fahrenheit"]],
    wind: [["km/h", "kmh", 1], ["mph", "mph", 1.609], ["m/s", "ms", 3.6], ["kn", "kn", 1.852]], // [label, api, factor to km/h]
    pressure: [["hPa"], ["inHg"], ["mmHg"]],
    precip: [["mm", "mm"], ["in", "inch"]]
};
function pressureText(hpa, u) {
    return u === 1 ? (hpa * 0.02953).toFixed(2) : u === 2 ? Math.round(hpa * 0.75006) : Math.round(hpa);
}

// u = {temp, wind, precip, model} (indices into UNITS, model key)
function forecastUrl(p, u) {
    return "https://api.open-meteo.com/v1/forecast?latitude=" + p.lat + "&longitude=" + p.lon
        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,is_day,precipitation,weather_code,cloud_cover,pressure_msl,wind_speed_10m,wind_direction_10m,wind_gusts_10m"
        + "&hourly=temperature_2m,precipitation_probability,precipitation,weather_code,is_day,visibility,uv_index"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max,precipitation_sum"
        + "&timezone=auto&past_days=1&forecast_days=8&temperature_unit=" + UNITS.temp[u.temp][1] // past day: rain over the last 24 h; 8 days: 7 left once days before local today are dropped
        + "&wind_speed_unit=" + UNITS.wind[u.wind][1] + "&precipitation_unit=" + UNITS.precip[u.precip][1]
        + (u.model && u.model !== "best_match" ? "&models=" + u.model : "");
}

// Open-Meteo times are location-local ISO strings; we never convert them, only slice.
function normalize(r, nHours) {
    const c = r.current, h = r.hourly, d = r.daily;
    let i = h.time.findIndex(t => t.substr(0, 13) === c.time.substr(0, 13));
    if (i < 0) i = 0;
    const hours = [];
    for (let k = i; k < Math.min(i + nHours, h.time.length); k++) {
        if (h.temperature_2m[k] === null) break; // some models (e.g. Météo-France) stop after ~4 days
        hours.push(Object.assign({ time: h.time[k], temp: h.temperature_2m[k], pop: h.precipitation_probability[k] ?? null },
                                 info(h.weather_code[k], h.is_day[k])));
    }
    const today = c.time.substr(0, 10);
    const days = d.time.map((t, k) => k).filter(k => d.time[k] >= today && d.temperature_2m_max[k] !== null && d.temperature_2m_min[k] !== null).map(k => { const t = d.time[k]; return Object.assign({
        date: t, max: d.temperature_2m_max[k], min: d.temperature_2m_min[k], pop: d.precipitation_probability_max[k] || 0,
        sunrise: d.sunrise[k], sunset: d.sunset[k], uv: d.uv_index_max[k], precip: d.precipitation_sum[k]
    }, info(d.weather_code[k], 1)); }).slice(0, 7);
    // Hourly precipitation is the amount over the preceding hour, so hours up to the current one have fallen already.
    // c.precipitation only covers the last 15 minutes: 0 right after a whole day of rain.
    const rain = h.precipitation || [], sum = (a, b) => { let s = 0; for (let k = Math.max(0, a); k <= b; k++) s += rain[k] || 0; return Math.round(s * 100) / 100; };
    let first = h.time.findIndex(t => t.substr(0, 10) === today); if (first < 0) first = i;
    const now = Object.assign({}, c, info(c.weather_code, c.is_day), { visibility: h.visibility[i], uv: h.uv_index[i],
        rainToday: sum(first, i), rain24h: sum(i - 23, i) });
    return { now: now, hours: hours, days: days, units: r.current_units };
}

// One plain-language line: what to expect next (glanceable "so what?" instead of making people read charts)
function summary(wx, h24, fahrenheit) {
    const now = wx.now, hrs = wx.hours.slice(0, 12);
    const wet = k => k === "rain" || k === "snow" || k === "storm";
    const noun = k => k === "snow" ? "Snow" : k === "storm" ? "Thunderstorms" : "Rain";
    if (wet(now.kind)) {
        const j = hrs.findIndex(h => !wet(h.kind));
        return j < 0 ? noun(now.kind) + " continuing through the next 12 hours" : noun(now.kind) + " easing around " + hourLabel(hrs[j].time, h24);
    }
    const j = hrs.findIndex(h => wet(h.kind));
    if (j > 0) return noun(hrs[j].kind) + " expected around " + hourLabel(hrs[j].time, h24);
    const d = now.apparent_temperature - now.temperature_2m;
    if (Math.abs(d) >= (fahrenheit ? 5 : 3)) return "Feels " + Math.abs(Math.round(d)) + "° " + (d < 0 ? "colder" : "warmer") + " than the actual temperature";
    return "Dry for the next 12 hours";
}

// ---- moon phase (computed locally; accurate to roughly a day, plenty for display) ----
const SYNODIC = 29.530588853;
function moon(date, lat) {
    const jd = date.getTime() / 86400000 + 2440587.5;
    const age = (((jd - 2451550.1) % SYNODIC) + SYNODIC) % SYNODIC; // days since the 2000-01-06 new moon
    const f = age / SYNODIC; // 0 new … 0.5 full … 1 new
    const name = f < 0.0339 || f >= 0.9661 ? "New Moon" : f < 0.2161 ? "Waxing Crescent" : f < 0.2839 ? "First Quarter"
        : f < 0.4661 ? "Waxing Gibbous" : f < 0.5339 ? "Full Moon" : f < 0.7161 ? "Waning Gibbous"
        : f < 0.7839 ? "Last Quarter" : "Waning Crescent";
    const until = target => new Date(date.getTime() + ((((target - f) % 1) + 1) % 1) * SYNODIC * 86400000);
    const fmt = d => Qt.locale().monthName(d.getMonth(), 1) + " " + d.getDate();
    return { phase: f, age: age, illum: Math.round((1 - Math.cos(2 * Math.PI * f)) / 2 * 100), name: name,
             mirror: lat < 0, // southern hemisphere sees the phase mirrored
             nextFull: fmt(until(0.5)), nextNew: fmt(until(0)) };
}

// Geocoder only matches names in the requested language, so pick it from the script the user typed.
function searchLang(q) {
    return /[\u0600-\u06FF]/.test(q) ? "fa" : /[\u0400-\u04FF]/.test(q) ? "ru" : /[\u4E00-\u9FFF]/.test(q) ? "zh"
        : /[\u3040-\u30FF]/.test(q) ? "ja" : /[\uAC00-\uD7AF]/.test(q) ? "ko" : /[\u0900-\u097F]/.test(q) ? "hi" : "en";
}
