// Temperature format converter for LiquidGlass
// Reads UNIT_TEMP variable (C or F) and converts temperature accordingly
// HA returns temperature in Celsius

function Initialize() {
}

function Update() {
    var unit = GetVariable("UNIT_TEMP");
    var tempC = GetMeasureValue("MeasureWxTemp");
    
    if (!tempC || tempC === "0" || tempC === "unavailable" || tempC === "unknown") {
        return "\u2014";
    }
    
    var temp = parseFloat(tempC);
    if (isNaN(temp)) return "\u2014";
    
    if (unit === "F") {
        // Convert Celsius to Fahrenheit
        var tempF = Math.round(temp * 9/5 + 32);
        return tempF + "\u00B0F";
    }
    
    // Celsius
    return Math.round(temp) + "\u00B0C";
}

function GetVariable(name) {
    var varObj = Variable(name);
    return varObj ? varObj.GetValue() : "F";
}

function GetMeasureValue(name) {
    var measure = Measure(name);
    return measure ? measure.GetValue() : "";
}