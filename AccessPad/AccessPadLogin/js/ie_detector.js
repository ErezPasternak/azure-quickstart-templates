
function msieversion() {
    var ua = window.navigator.userAgent;
    var msie = ua.indexOf("MSIE ");

    if (msie > 0 && parseInt(ua.substring(msie + 5, ua.indexOf(".", msie))) < 10) {      // If Internet Explorer, return version number
        alert('browser not supported. Please update to the latest version.')
    }
    return false;
}

msieversion();

      // org.apache.cordova.statusbar required

var history_api = typeof history.pushState !== 'undefined';
// history.pushState must be called out side of AngularJS Code
if (history_api) history.pushState(null, '', '#StayHere');  // After the # you should write something, do not leave it empty