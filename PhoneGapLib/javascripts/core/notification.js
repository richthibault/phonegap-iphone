/**
 * This class provides access to notifications on the device.
 */
function Notification() {
	
}

/**
 * Causes the device to blink a status LED.
 * @param {Integer} count The number of blinks.
 * @param {String} colour The colour of the light.
 */
Notification.prototype.blink = function(count, colour) {
	
};

Notification.prototype.vibrate = function(mills) {
	PhoneGap.exec("Notification.vibrate");
};

Notification.prototype.beep = function(count, volume) {
	// No Volume yet for the iphone interface
	// We can use a canned beep sound and call that
	new Media('beep.wav').play();
};

Notification.prototype.alert = function(message, title, okLabel, cancelLabel, options) {
    var args = {};
    if (title) args.title = title;
    if (okLabel) args.okLabel = okLabel;
    if (cancelLabel) args.cancelLabel = cancelLabel;
    if (typeof(options) == 'object' && "onClose" in options)
        args.onClose = PhoneGap.registerCallback(options.onClose);

    if (PhoneGap.available)
        PhoneGap.exec('Notification.alert', message, args);
    else
        alert(message);
};

Notification.prototype.activityStart = function() {
    PhoneGap.exec("Notification.activityStart");
};
Notification.prototype.activityStop = function() {
    PhoneGap.exec("Notification.activityStop");
};

Notification.prototype.loadingStart = function(options) {
    PhoneGap.exec("Notification.loadingStart", options);
};
Notification.prototype.loadingStop = function() {
    PhoneGap.exec("Notification.loadingStop");
};

PhoneGap.addConstructor(function() {
    if (typeof navigator.notification == "undefined") navigator.notification = new Notification();
});

