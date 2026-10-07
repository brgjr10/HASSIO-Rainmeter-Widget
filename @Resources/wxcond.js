// Weather condition mapper for Home Assistant
// Reads MeasureWxState (condition code) and returns human-readable text

function Initialize() {
}

function Update() {
    var condition = GetMeasureValue("MeasureWxState");
    if (!condition || condition === "0" || condition === "unavailable" || condition === "unknown") {
        return "\u2014";
    }

    var map = {
        "clear-night": "Clear Night",
        "cloudy": "Cloudy",
        "fog": "Fog",
        "hail": "Hail",
        "lightning": "Thunderstorm",
        "lightning-rainy": "Thunderstorm",
        "partlycloudy": "Partly Cloudy",
        "pouring": "Pouring",
        "rainy": "Rain",
        "snowy": "Snow",
        "snowy-rainy": "Rain/Snow",
        "sunny": "Sunny",
        "windy": "Windy",
        "windy-variant": "Windy",
        "exceptional": "Extreme"
    };

    return map[condition.toLowerCase()] || condition;
}

function GetMeasureValue(name) {
    var measure = Measure(name);
    return measure ? measure.GetValue() : "";
}