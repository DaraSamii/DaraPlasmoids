// Loads contents/code/weather.js (a QML `.pragma library`) into plain Node for testing.
const fs = require("fs"), path = require("path"), vm = require("vm");
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
module.exports = function load() {
    let src = fs.readFileSync(path.join(__dirname, "../weather/contents/code/weather.js"), "utf8");
    src = src.replace(/^\.pragma library\s*$/m, "");
    const names = [...src.matchAll(/^(?:function\s+|const\s+)(\w+)/gm)].map(m => m[1]);
    const ctx = vm.createContext({
        Qt: { locale: () => ({ dayName: d => DAYS[d], monthName: m => MONTHS[m] }) },
        encodeURIComponent, Math, Date, JSON, Object, Array, isNaN, parseInt
    });
    return vm.runInContext(src + "\n;({" + names.join(",") + "})", ctx);
};
