// Time format converter for LiquidGlass
// Reads TIME_FORMAT variable (12 or 24) and formats time accordingly

function Initialize() {
}

function Update() {
    var format = GetVariable("TIME_FORMAT");
    var timeStr = GetMeasureValue("MeasureTimeRaw");
    
    if (!timeStr) return "";
    
    if (format === "12") {
        // Convert 24h to 12h with AM/PM
        var parts = timeStr.split(":");
        var hours = parseInt(parts[0], 10);
        var minutes = parts[1];
        var ampm = hours >= 12 ? "PM" : "AM";
        hours = hours % 12;
        if (hours === 0) hours = 12;
        return hours + ":" + minutes + " " + ampm;
    }
    
    return timeStr; // 24h format
}

function GetVariable(name) {
    var varObj = Variable(name);
    return varObj ? varObj.GetValue() : "24";
}

function GetMeasureValue(name) {
    var measure = Measure(name);
    return measure ? measure.GetValue() : "";
}