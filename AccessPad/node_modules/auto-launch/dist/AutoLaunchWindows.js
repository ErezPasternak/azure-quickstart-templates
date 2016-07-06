var Promise, Winreg, regKey;

Winreg = require('winreg');

Promise = require('es6-promise').Promise;

regKey = new Winreg({
  hive: Winreg.HKCU,
  key: '\\Software\\Microsoft\\Windows\\CurrentVersion\\Run'
});

module.exports = {
  regKey: regKey,
  enable: function(opts) {
    return new Promise(function(resolve, reject) {
      return regKey.set(opts.appName, Winreg.REG_SZ, "\"" + opts.appPath + "\"", function(err) {
        if (err != null) {
          return reject(err);
        }
        return resolve();
      });
    });
  },
  disable: function(opts) {
    return new Promise(function(resolve, reject) {
      return regKey.remove(opts.appName, function(err) {
        if (err != null) {
          return reject(err);
        }
        return resolve();
      });
    });
  },
  isEnabled: function(opts) {
    return new Promise(function(resolve, reject) {
      return regKey.get(opts.appName, function(err, item) {
        return resolve(item != null);
      });
    });
  }
};
