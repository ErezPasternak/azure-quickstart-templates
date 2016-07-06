const electron = require('electron')

// Module to control application life.
const app = electron.app
// Module to create native browser window.
const BrowserWindow = electron.BrowserWindow

var deleteChromeCache = function() {
    var chromeCacheDir = path.join(app.getPath('userData'), 'Cache'); 
    if(fs.existsSync(chromeCacheDir)) {
        var files = fs.readdirSync(chromeCacheDir);
        for(var i=0; i<files.length; i++) {
            var filename = path.join(chromeCacheDir, files[i]);
            if(fs.existsSync(filename)) {
                try {
                    fs.unlinkSync(filename);
                }
                catch(e) {
                    console.log(e);
                }
            }
        }
    }
};

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow
 
function createWindow () {
  // Create the browser window.
 
  mainWindow = new BrowserWindow({width: 1000, height: 800})
 

  // and load the index.html of the app.
  //mainWindow.loadURL(`file://${__dirname}/www/index.html`)
  
  
  mainWindow.loadURL(`file://${__dirname}/AccessPadLogin/login.html`)
  //mainWindow.loadURL(`http://rdcb.ericom.com:8033/EricomXML/AccessPortal/index.html?ver=1`)
  //mainWindow.loadURL(`http://srv12lo2-3.cloudconnect.local/ericomxml/accessportal/index.html`)
 //mainWindow.loadURL(`http://ec76.test.local:8033/EricomXml/AccessPortal/index.html?ver=5`)

  // Open the DevTools.
mainWindow.webContents.openDevTools()
var AutoLaunch = require('auto-launch');

var appLauncher = new AutoLaunch({
    name: 'AccessPad'
});

appLauncher.isEnabled().then(function(enabled){
    if(enabled) return;
    return appLauncher.enable()
}).then(function(err){

});
var fullname = require('fullname');

fullname().then(name => {
    console.log(name);
    //=> 'Sindre Sorhus'
});
  // Emitted when the window is closed.
  mainWindow.on('closed', function () {
    // Dereference the window object, usually you would store windows
    // in an array if your app supports multi windows, this is the time
    // when you should delete the corresponding element.
    mainWindow = null
  })
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', createWindow)

// Quit when all windows are closed.
app.on('window-all-closed', function () {
  // On OS X it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('activate', function () {
  // On OS X it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (mainWindow === null) {
    createWindow()
  }
})

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.
