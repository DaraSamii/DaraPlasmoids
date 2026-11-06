// Live tests against Open-Meteo (needs internet):  node tests/live.test.js
const assert = require("assert");
const W = require("./load")();
const CITIES = [
    { name: "Montreal", lat: 45.5088, lon: -73.5878 }, { name: "Tehran", lat: 35.6892, lon: 51.389 },
    { name: "Sydney", lat: -33.8688, lon: 151.2093 }, { name: "Honolulu", lat: 21.3069, lon: -157.8583 },
    { name: "Reykjavik", lat: 64.1466, lon: -21.9426 }, { name: "Singapore", lat: 1.3521, lon: 103.8198 },
    { name: "Quito", lat: -0.1807, lon: -78.4678 }
];
let ok = 0, bad = 0;
const check = (label, fn) => { try { fn(); ok++; } catch (e) { bad++; console.error("FAIL", label, "-", e.message); } };
const get = async url => { const r = await fetch(url); if (!r.ok) throw new Error("HTTP " + r.status + " " + url); return r.json(); };

(async () => {
    for (const model of W.MODELS.map(m => m[0])) for (const city of CITIES) {
        const label = model + " / " + city.name;
        let raw;
        try { raw = await get(W.forecastUrl(city, { temp: 0, wind: 0, precip: 0, model })); } catch (e) { check(label + " fetch", () => { throw e; }); continue; }
        check(label, () => {
            const n = W.normalize(raw, 48);
            assert.strictEqual(n.hours.length, 48); if (model !== "meteofrance_seamless") assert.strictEqual(n.days.length, 7);
            assert(n.now.temperature_2m > -60 && n.now.temperature_2m < 60, "temp " + n.now.temperature_2m);
            assert(n.now.relative_humidity_2m >= 0 && n.now.relative_humidity_2m <= 100);
            assert(n.now.pressure_msl > 850 && n.now.pressure_msl < 1100);
            assert(n.now.wind_direction_10m >= 0 && n.now.wind_direction_10m <= 360);
            assert(n.now.text !== "Unknown", "weather code " + raw.current.weather_code);
            assert(/^\d{4}-\d\d-\d\dT\d\d:\d\d$/.test(n.days[0].sunrise) && /^\d{4}-\d\d-\d\dT\d\d:\d\d$/.test(n.days[0].sunset));
            if (model === "meteofrance_seamless") assert(n.days.length >= 3 && n.days.length <= 7, "mf days " + n.days.length);
            n.days.forEach(d => { assert(d.max >= d.min, "max<min " + d.date); assert(d.text !== "Unknown"); });
            n.hours.forEach(h => assert(h.pop === null || (h.pop >= 0 && h.pop <= 100)));
            W.summary(n, false); W.moon(new Date(), city.lat);
        });
    }
    // every unit combination is accepted by the API and units really change
    const base = W.normalize(await get(W.forecastUrl(CITIES[0], { temp: 0, wind: 0, precip: 0, model: "best_match" })), 24);
    const imp = W.normalize(await get(W.forecastUrl(CITIES[0], { temp: 1, wind: 1, precip: 1, model: "best_match" })), 24);
    check("units: °F is consistent with °C", () => assert(Math.abs(imp.now.temperature_2m - (base.now.temperature_2m * 9 / 5 + 32)) < 4, imp.now.temperature_2m + " vs " + base.now.temperature_2m));
    check("units: mph < km/h", () => assert(imp.now.wind_speed_10m <= base.now.wind_speed_10m + 0.5));
    for (const w of [2, 3]) await get(W.forecastUrl(CITIES[0], { temp: 0, wind: w, precip: 0, model: "best_match" })).then(() => ok++, e => { bad++; console.error("FAIL wind unit", w, e.message); });
    // city search
    for (const q of ["Montreal", "Tehran", "Zürich", "São Paulo", "New York", "Springfield", "Łódź", "تهران", "Москва", "東京", "Reykjavík", "zz"]) {
        try {
            const r = await get("https://geocoding-api.open-meteo.com/v1/search?count=6&language=" + W.searchLang(q) + "&name=" + encodeURIComponent(q));
            const list = (r.results || []).map(x => ({ name: x.name, admin1: x.admin1, country: x.country, lat: x.latitude, lon: x.longitude }));
            check("search " + q, () => { if (q !== "zz") assert(list.length > 0, "no results"); list.forEach(p => { assert(typeof p.lat === "number" && typeof p.lon === "number"); assert(W.placeLabel(p).length > 0); }); });
        } catch (e) { bad++; console.error("FAIL search", q, e.message); }
    }
    console.log(ok + " passed, " + bad + " failed");
    process.exit(bad ? 1 : 0);
})();
