var Promise, fs, mkdirp, untildify;

fs = require('fs');

mkdirp = require('mkdirp');

untildify = require('untildify');

Promise = require('es6-promise').Promise;

module.exports = {
  getDir: function(opts) {
    return untildify("~/.config/autostart/");
  },
  getFile: function(opts) {
    var file;
    file = this.getDir() + opts.appName + '.desktop';
    return file;
  },
  enable: function(opts) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var data, file;
        file = _this.getFile(opts);
        data = ['[Desktop Entry]', 'Type=Application', 'Vestion=1.0', 'Name=' + opts.appName, 'Comment=' + opts.appName + ' startup script', 'Exec=' + opts.appPath, 'StartupNotify=false', 'Terminal=false'].join('\n');
        mkdirp.sync(_this.getDir());
        return fs.writeFile(file, data, function(err) {
          if (err != null) {
            return reject(err);
          }
          return resolve();
        });
      };
    })(this));
  },
  disable: function(opts) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var file;
        file = _this.getFile(opts);
        return fs.stat(file, function(err) {
          if (err != null) {
            return reject(err);
          }
          return fs.unlink(file, function(err2) {
            if (err != null) {
              return reject(err2);
            }
            return resolve();
          });
        });
      };
    })(this));
  },
  isEnabled: function(opts) {
    return new Promise((function(_this) {
      return function(resolve, reject) {
        var file;
        file = _this.getFile(opts);
        return fs.stat(file, function(err, stat) {
          return resolve(stat != null);
        });
      };
    })(this));
  }
};
