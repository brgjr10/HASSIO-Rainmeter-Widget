// Brightness click calculator for LiquidGlass
// Converts skin-relative mouse X to 0-255 brightness for a bar at given position

function Initialize() {
}

function Update() {
    var mouseX = GetVariable("MOUSE_X");
    var barX = GetVariable("BAR_X");
    var barWidth = GetVariable("BAR_WIDTH");
    
    if (!mouseX || !barX || !barWidth) return "0";
    
    var x = parseInt(mouseX, 10);
    var bx = parseInt(barX, 10);
    var bw = parseInt(barWidth, 10);
    
    // Calculate relative position within bar (0 to 1)
    var rel = (x - bx) / bw;
    
    // Clamp to 0-1
    if (rel < 0) rel = 0;
    if (rel > 1) rel = 1;
    
    // Map to 0-255
    var brightness = Math.round(rel * 255);
    
    return brightness.toString();
}

function GetVariable(name) {
    var varObj = Variable(name);
    return varObj ? varObj.GetValue() : "";
}