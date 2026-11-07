// Offline unit tests for weather.js:  node tests/weather.test.js
const assert = require("assert");
const W = require("./load")();
let passed = 0;
const t = (name, fn) => { try { fn(); passed++; } catch (e) { console.error("FAIL:", name, "\n  ", e.message); process.exitCode = 1; } };

// ---- weather codes / icons
t("every WMO code Open-Meteo can send maps to text+kind+icon", () => {
    [0, 1, 2, 3, 45, 48, 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 77, 80, 81, 82, 85, 86, 95, 96, 99].forEach(c => {
        const i = W.info(c, 1);
        assert(i.text && i.text !== "Unknown", "code " + c);
        assert(["clear", "cloudy", "rain", "snow", "storm", "fog"].includes(i.kind), "kind " + c);
        assert(i.icon.startsWith("weather-") && i.symbolic.endsWith("-symbolic"), "icon " + c);
    });
});
t("unknown code falls back safely", () => assert.strictEqual(W.info(1234, 1).icon, "weather-none-available"));
t("night variants only for icons that have them", () => {
    assert.strictEqual(W.info(0, 0).icon, "weather-clear-night");
    assert.strictEqual(W.info(63, 0).icon, "weather-showers-night");
    assert.strictEqual(W.info(45, 0).icon, "weather-fog"); // no night variant exists
    assert.strictEqual(W.info(0, 1).icon, "weather-clear");
});
t("mono (symbolic) used for dark icons, colored for clear/few-clouds/clouds", () => {
    assert.strictEqual(W.info(0, 1).mono, false); assert.strictEqual(W.info(1, 1).mono, false); assert.strictEqual(W.info(2, 1).mono, false);
    assert.strictEqual(W.info(3, 1).mono, true); assert.strictEqual(W.info(95, 1).mono, true);
});

// ---- time formatting
t("hour labels 12h: a.m./p.m., midnight and noon", () => {
    assert.strictEqual(W.hourLabel("2026-11-06T00:00", false), "12 a.m.");
    assert.strictEqual(W.hourLabel("2026-11-06T02:00", false), "2 a.m.");
    assert.strictEqual(W.hourLabel("2026-11-06T12:00", false), "12 p.m.");
    assert.strictEqual(W.hourLabel("2026-11-06T15:00", false), "3 p.m.");
    assert.strictEqual(W.hourLabel("2026-11-06T23:00", false), "11 p.m.");
});
t("hour labels 24h are zero padded", () => {
    assert.strictEqual(W.hourLabel("2026-11-06T02:00", true), "02");
    assert.strictEqual(W.hourLabel("2026-11-06T23:00", true), "23");
});
t("time labels", () => {
    assert.strictEqual(W.timeLabel("2026-11-06T06:41", false), "6:41 a.m.");
    assert.strictEqual(W.timeLabel("2026-11-06T16:34", false), "4:34 p.m.");
    assert.strictEqual(W.timeLabel("2026-11-06T00:05", false), "12:05 a.m.");
    assert.strictEqual(W.timeLabel("2026-11-06T06:41", true), "06:41");
});
t("mins / duration", () => {
    assert.strictEqual(W.mins("2026-11-06T06:41"), 401);
    assert.strictEqual(W.duration("2026-11-06T06:41", "2026-11-06T16:34"), "9h 53m");
    assert.strictEqual(W.duration("2026-06-21T05:00", "2026-06-21T21:05"), "16h 05m");
});
t("day names and short dates", () => {
    assert.strictEqual(W.dayName("2026-11-07", 0), "Today");
    assert.strictEqual(W.dayName("2026-11-07", 1), "Sat");
    assert.strictEqual(W.dateShort("2026-11-07"), "Nov 7");
    assert.strictEqual(W.dateShort("2026-12-25"), "Dec 25");
});

// ---- small helpers
t("compass wraps and rounds", () => {
    assert.strictEqual(W.compass(0), "N"); assert.strictEqual(W.compass(360), "N"); assert.strictEqual(W.compass(350), "N");
    assert.strictEqual(W.compass(90), "E"); assert.strictEqual(W.compass(222), "SW"); assert.strictEqual(W.compass(315), "NW");
});
t("UV bands", () => {
    assert.strictEqual(W.uvLabel(0), "Low"); assert.strictEqual(W.uvLabel(2.9), "Low"); assert.strictEqual(W.uvLabel(3), "Moderate");
    assert.strictEqual(W.uvLabel(6), "High"); assert.strictEqual(W.uvLabel(8), "Very high"); assert.strictEqual(W.uvLabel(11), "Extreme");
});
t("num() handles null/undefined (models without data)", () => {
    assert.strictEqual(W.num(null), "–"); assert.strictEqual(W.num(undefined), "–");
    assert.strictEqual(W.num(0), 0); assert.strictEqual(W.num(3.6), 4); assert.strictEqual(W.num(3.14159, 2), "3.14");
});
t("pressure units", () => {
    assert.strictEqual(W.pressureText(1013.25, 0), 1013); assert.strictEqual(W.pressureText(1013.25, 1), "29.92");
    assert.strictEqual(W.pressureText(1013.25, 2), 760);
});

// ---- places
const MTL = { name: "Montreal", admin1: "Quebec", country: "Canada", lat: 45.5088, lon: -73.5878 };
const THR = { name: "Tehran", admin1: "Tehran", country: "Iran", lat: 35.6892, lon: 51.389 };
t("parsePlaces tolerates garbage", () => {
    const j = x => JSON.stringify(W.parsePlaces(x)); // JSON compare: arrays from the VM realm differ by prototype
    assert.strictEqual(j("not json"), "[]"); assert.strictEqual(j(""), "[]"); assert.strictEqual(j('{"a":1}'), "[]"); assert.strictEqual(j(undefined), "[]");
});
t("addPlace appends, selects, and de-duplicates by coordinates", () => {
    let r = W.addPlace(JSON.stringify([MTL]), THR);
    assert.strictEqual(r.index, 1); assert.strictEqual(W.parsePlaces(r.json).length, 2);
    r = W.addPlace(r.json, Object.assign({}, MTL, { lat: 45.5089 })); // same place, tiny coordinate drift
    assert.strictEqual(r.index, 0); assert.strictEqual(W.parsePlaces(r.json).length, 2);
});
t("addPlace works from an empty/corrupt list", () => {
    const r = W.addPlace("garbage", MTL); assert.strictEqual(r.index, 0); assert.strictEqual(W.parsePlaces(r.json).length, 1);
});
t("removePlace never removes the last place", () => {
    const two = JSON.stringify([MTL, THR]);
    assert.strictEqual(W.parsePlaces(W.removePlace(two, 0))[0].name, "Tehran");
    assert.strictEqual(W.parsePlaces(W.removePlace(JSON.stringify([MTL]), 0)).length, 1);
});
t("placeLabel skips missing parts", () => {
    assert.strictEqual(W.placeLabel(MTL), "Montreal, Quebec, Canada"); assert.strictEqual(W.placeLabel({ name: "X" }), "X");
});

// ---- URLs
t("forecastUrl: units and model mapping for every combination", () => {
    for (let tU = 0; tU < 2; tU++) for (let w = 0; w < 4; w++) for (let p = 0; p < 2; p++) for (const m of W.MODELS.map(x => x[0])) {
        const u = W.forecastUrl(MTL, { temp: tU, wind: w, precip: p, model: m });
        assert(u.includes("temperature_unit=" + ["celsius", "fahrenheit"][tU]));
        assert(u.includes("wind_speed_unit=" + ["kmh", "mph", "ms", "kn"][w]));
        assert(u.includes("precipitation_unit=" + ["mm", "inch"][p]));
        assert(u.includes("latitude=45.5088") && u.includes("longitude=-73.5878") && u.includes("timezone=auto"));
        assert.strictEqual(u.includes("models="), m !== "best_match");
    }
});
t("siteUrl fills every template, encodes names", () => {
    W.SITES.forEach(s => {
        const u = W.siteUrl(s[0], { name: "São Paulo", lat: -23.55, lon: -46.63 });
        assert(!u.includes("{") && u.startsWith("https://"), s[0]);
    });
    assert(W.siteUrl("google", { name: "São Paulo", lat: 0, lon: 0 }).includes("S%C3%A3o%20Paulo"));
    assert(W.siteUrl("windy", MTL).includes("45.5088/-73.5878"));
    assert(W.siteUrl("nonsense", MTL).includes("windy")); // unknown key falls back to the first site
});
t("labels", () => { assert.strictEqual(W.modelLabel("gem_seamless"), "GEM — Environment Canada"); assert.strictEqual(W.modelLabel("zzz"), "zzz"); assert.strictEqual(W.siteLabel("yr"), "Yr (MET Norway)"); });

// ---- normalize + summary on synthetic API data
function api(over = {}) {
    const times = [], N = 168; // 7 days of hours from 2026-11-06T00:00
    for (let k = 0; k < N; k++) { const d = 6 + Math.floor(k / 24); times.push("2026-11-" + (d < 10 ? "0" : "") + d + "T" + (k % 24 < 10 ? "0" : "") + (k % 24) + ":00"); }
    const arr = (v) => times.map((_, k) => typeof v === "function" ? v(k) : v);
    const r = {
        current: { time: "2026-11-06T13:15", temperature_2m: 12.4, apparent_temperature: 10.1, relative_humidity_2m: 70, is_day: 1, precipitation: 0,
                   weather_code: 2, cloud_cover: 40, pressure_msl: 1012, wind_speed_10m: 12, wind_direction_10m: 225, wind_gusts_10m: 20 },
        hourly: { time: times, temperature_2m: arr(k => 10 + (k % 24) / 2), precipitation_probability: arr(0), weather_code: arr(2), is_day: arr(1), visibility: arr(20000), uv_index: arr(1) },
        daily: { time: [...new Set(times.map(x => x.slice(0, 10)))], weather_code: arr(2).slice(0, 7), temperature_2m_max: [14, 9, 8, 7, 6, 5, 4], temperature_2m_min: [6, 3, 2, 1, 0, -1, -2],
                 sunrise: [...Array(7)].map((_, i) => "2026-11-0" + (6 + i > 9 ? 9 : 6 + i) + "T06:41"), sunset: [...Array(7)].map(() => "2026-11-06T16:34"),
                 uv_index_max: arr(3).slice(0, 7), precipitation_probability_max: [10, 20, 30, 40, 50, 60, 70], precipitation_sum: [0, 1, 2, 3, 4, 5, 6] },
        current_units: {}
    };
    for (const [k, v] of Object.entries(over)) { const [a, b] = k.split("."); (b ? r[a] : r)[b || a] = v; }
    return r;
}
t("normalize: starts at the current hour and returns N hours", () => {
    const n = W.normalize(api(), 24);
    assert.strictEqual(n.hours.length, 24); assert.strictEqual(n.hours[0].time, "2026-11-06T13:00");
    assert.strictEqual(W.normalize(api(), 12).hours.length, 12); assert.strictEqual(W.normalize(api(), 48).hours.length, 48);
    assert.strictEqual(n.days.length, 7); assert.strictEqual(n.now.text, "Partly cloudy");
});
t("normalize: asking for more hours than exist is clamped, not an error", () => {
    const n = W.normalize(api(), 500); assert(n.hours.length <= 168 && n.hours.length > 100);
});
t("normalize: unknown current hour falls back to index 0", () => {
    const n = W.normalize(api({ "current.time": "2030-01-01T00:00" }), 24); assert.strictEqual(n.hours[0].time, "2026-11-06T00:00");
});
t("normalize: models without data keep null (not 0)", () => {
    const n = W.normalize(api({ "hourly.precipitation_probability": api().hourly.time.map(() => null), "hourly.visibility": api().hourly.time.map(() => null),
                                "hourly.uv_index": api().hourly.time.map(() => null), "current.wind_gusts_10m": null }), 24);
    assert.strictEqual(n.hours[0].pop, null); assert.strictEqual(n.now.visibility, null); assert.strictEqual(n.now.uv, null); assert.strictEqual(n.now.wind_gusts_10m, null);
});
t("normalize: real 0% rain chance stays 0, not null", () => assert.strictEqual(W.normalize(api(), 24).hours[0].pop, 0));
t("normalize: day/night icon follows is_day", () => {
    const o = api(); o.hourly.is_day = o.hourly.time.map(() => 0); o.hourly.weather_code = o.hourly.time.map(() => 0);
    assert.strictEqual(W.normalize(o, 24).hours[0].icon, "weather-clear-night");
});
t("normalize: models with a short horizon (Météo-France ~4 days) are cut cleanly, no NaN rows", () => {
    const o = api(); const cut = 98;
    o.hourly.temperature_2m = o.hourly.temperature_2m.map((v, k) => (k >= cut ? null : v));
    ["temperature_2m_max", "temperature_2m_min", "weather_code"].forEach(key => { o.daily[key] = o.daily[key].map((v, k) => (k >= 4 ? null : v)); });
    const n = W.normalize(o, 168);
    assert.strictEqual(n.days.length, 4); n.days.forEach(d => { assert(Number.isFinite(d.max) && Number.isFinite(d.min)); assert(d.text !== "Unknown"); });
    assert.strictEqual(n.hours.length, cut - 13); n.hours.forEach(h => assert(Number.isFinite(h.temp)));
});
t("normalize: rain so far today and over the last 24 h come from the hourly amounts, not the 15-minute current value", () => {
    const o = api(); o.hourly.precipitation = o.hourly.time.map(() => 1); // 1 mm every hour; current is 13:15 on the first day
    const n = W.normalize(o, 24);
    assert.strictEqual(n.now.precipitation, 0);
    assert.strictEqual(n.now.rainToday, 14); // 00:00 .. 13:00
    assert.strictEqual(n.now.rain24h, 14);   // only 14 hours exist before now in this fixture
    const m = W.normalize(api({ "current.time": "2026-11-07T02:00" }), 24); assert.strictEqual(m.now.rainToday, 0); // no precipitation array: 0, not NaN
    o.current.time = "2026-11-07T02:00"; const p = W.normalize(o, 24);
    assert.strictEqual(p.now.rainToday, 3); assert.strictEqual(p.now.rain24h, 24);
});
t("normalize: days before today (past_days) are dropped, so days[0] is today", () => {
    const n = W.normalize(api({ "current.time": "2026-11-07T09:00" }), 24);
    assert.strictEqual(n.days[0].date, "2026-11-07"); assert.strictEqual(n.days.length, 6);
});
t("normalize: all-null forecast gives empty lists instead of throwing", () => {
    const o = api(); o.hourly.temperature_2m = o.hourly.temperature_2m.map(() => null);
    ["temperature_2m_max", "temperature_2m_min"].forEach(key => { o.daily[key] = o.daily[key].map(() => null); });
    const n = W.normalize(o, 24); assert.strictEqual(n.hours.length, 0); assert.strictEqual(n.days.length, 0);
});
t("searchLang picks the geocoder language from the script typed", () => {
    assert.strictEqual(W.searchLang("Montreal"), "en"); assert.strictEqual(W.searchLang("Zürich"), "en"); assert.strictEqual(W.searchLang("تهران"), "fa");
    assert.strictEqual(W.searchLang("Москва"), "ru"); assert.strictEqual(W.searchLang("東京"), "zh"); assert.strictEqual(W.searchLang("서울"), "ko");
    assert.strictEqual(W.searchLang("दिल्ली"), "hi"); assert.strictEqual(W.searchLang("とうきょう"), "ja");
});
t("summary: dry", () => assert.strictEqual(W.summary(W.normalize(api(), 24), false), "Dry for the next 12 hours"));
t("summary: rain coming", () => {
    const o = api(); o.hourly.weather_code = o.hourly.time.map((_, k) => (k === 13 + 5 ? 63 : 2));
    assert.strictEqual(W.summary(W.normalize(o, 24), false), "Rain expected around 6 p.m.");
});
t("summary: raining now, easing later; and continuing", () => {
    const o = api(); o.current.weather_code = 63; o.hourly.weather_code = o.hourly.time.map((_, k) => (k < 13 + 3 ? 63 : 2));
    assert.strictEqual(W.summary(W.normalize(o, 24), false), "Rain easing around 4 p.m.");
    const p = api(); p.current.weather_code = 73; p.hourly.weather_code = p.hourly.time.map(() => 73);
    assert.strictEqual(W.summary(W.normalize(p, 24), false), "Snow continuing through the next 12 hours");
});
t("summary: feels colder/warmer", () => {
    const o = api(); o.current.apparent_temperature = 5; assert(/Feels 7° colder/.test(W.summary(W.normalize(o, 24), false)));
    const p = api(); p.current.apparent_temperature = 18; assert(/Feels 6° warmer/.test(W.summary(W.normalize(p, 24), false)));
});
t("summary: the feels-like threshold is wider in °F (5) than in °C (3)", () => {
    const o = api(); o.current.apparent_temperature = o.current.temperature_2m - 4;
    assert(/Feels 4° colder/.test(W.summary(W.normalize(o, 24), false, false)));
    assert.strictEqual(W.summary(W.normalize(o, 24), false, true), "Dry for the next 12 hours");
});
t("summary: thunderstorm wording, 24h clock", () => {
    const o = api(); o.hourly.weather_code = o.hourly.time.map((_, k) => (k === 13 + 4 ? 95 : 2));
    assert.strictEqual(W.summary(W.normalize(o, 24), true), "Thunderstorms expected around 17");
});

// ---- moon
const nearDay = (d, y, m, day) => Math.abs(d - new Date(Date.UTC(y, m - 1, day, 12))) < 1.6 * 86400000;
t("moon: known new moons are ~0% lit", () => {
    [[2024, 4, 8, 18], [2025, 1, 29, 12], [2000, 1, 6, 18]].forEach(([y, m, d, h]) => {
        const mo = W.moon(new Date(Date.UTC(y, m - 1, d, h)), 45); assert(mo.illum <= 3, y + "-" + m + "-" + d + " illum " + mo.illum); assert.strictEqual(mo.name, "New Moon");
    });
});
t("moon: known full moons are ~100% lit", () => {
    [[2024, 1, 25, 18], [2025, 3, 14, 7], [2026, 11, 24, 14]].forEach(([y, m, d, h]) => {
        const mo = W.moon(new Date(Date.UTC(y, m - 1, d, h)), 45); assert(mo.illum >= 97, y + "-" + m + "-" + d + " illum " + mo.illum); assert.strictEqual(mo.name, "Full Moon");
    });
});
t("moon: quarters and gibbous/crescent order over a full cycle", () => {
    const start = Date.UTC(2024, 3, 8, 19); const seen = [];
    for (let d = 0; d < 30; d++) { const n = W.moon(new Date(start + d * 86400000), 45).name; if (seen[seen.length - 1] !== n) seen.push(n); }
    assert.deepStrictEqual(Array.from(seen), ["New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous", "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent", "New Moon"]);
});
t("moon: next full/new within a lunar cycle and mirror flag by hemisphere", () => {
    const d = new Date(Date.UTC(2026, 10, 6, 6)); const mo = W.moon(d, 45.5);
    assert.strictEqual(mo.mirror, false); assert.strictEqual(W.moon(d, -33.9).mirror, true);
    assert(mo.phase >= 0 && mo.phase < 1 && mo.age >= 0 && mo.age < 29.54);
    assert(/^[A-Z][a-z]{2} \d{1,2}$/.test(mo.nextFull) && /^[A-Z][a-z]{2} \d{1,2}$/.test(mo.nextNew));
});
t("moon: phase is always within [0,1) for dates before and after the epoch", () => {
    [new Date(Date.UTC(1969, 6, 20)), new Date(Date.UTC(1999, 11, 31)), new Date(Date.UTC(2100, 0, 1))].forEach(d => { const m = W.moon(d, 0); assert(m.phase >= 0 && m.phase < 1); assert(m.illum >= 0 && m.illum <= 100); });
});

console.log(passed + " passed" + (process.exitCode ? " — with FAILURES" : ""));
