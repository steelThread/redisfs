(function() {
  var RedisFs, connectToRedis, fs, log, redis, temp, uuid, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  exports.version = '0.1.0';
  exports.redisfs = function(options) {
    return new exports.RedisFs(options);
  };
  _ = require('underscore');
  fs = require('fs');
  temp = require('temp');
  uuid = require('node-uuid');
  redis = require('redis');
  log = console.log;
  RedisFs = (function() {
    function RedisFs(options, keys) {
      if (options == null) {
        options = {};
      }
      this.keys = keys != null ? keys : [];
      this.redis = options.redis || connectToRedis(options);
      this.namespace = options.namespace || 'redisfs';
      if (options.database != null) {
        this.redis.select(options.database);
      }
    }
    RedisFs.prototype.file2redis = function(filename, options, callback) {
      var encoding, key;
      if (_.isFunction(options)) {
        callback = options;
        options = {};
      }
      key = options.key || ("" + this.namespace + ":" + (uuid()));
      encoding = options.encoding || 'utf8';
      if (!options.key) {
        this.keys.push(key);
      }
      return fs.readFile(filename, encoding, __bind(function(err, data) {
        if (err != null) {
          return callback(err);
        } else {
          return this.set(key, data, callback);
        }
      }, this));
    };
    RedisFs.prototype.redis2file = function(key, options, callback) {
      var encoding;
      if (_.isFunction(options)) {
        callback = options;
        options = {};
      }
      encoding = options.encoding || 'utf8';
      if (options.filename != null) {
        return this.get(key, __bind(function(err, value) {
          if (err != null) {
            return callback(err);
          } else {
            return this.write(options.filename, value, encoding, callback);
          }
        }, this));
      } else {
        return this.open(key, encoding, callback);
      }
    };
    RedisFs.prototype.end = function(cleanup, callback) {
      var key, multi, _i, _len, _ref;
      if (_.isFunction(cleanup)) {
        callback = cleanup;
      }
      if (cleanup === true) {
        multi = this.redis.multi();
        _ref = this.keys;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          key = _ref[_i];
          multi.del(key);
        }
        return multi.exec(__bind(function(err, replies) {
          if (err != null) {
            log("Unable to del all generated keys " + (JSON.stringify(replies)));
          }
          if (callback != null) {
            callback(err, replies);
          }
          return this.redis.quit();
        }, this));
      } else {
        return this.redis.quit();
      }
    };
    RedisFs.prototype.get = function(key, callback) {
      return this.redis.get(key, __bind(function(err, value) {
        if (typeof err == "function" ? err(callback(err)) : void 0) {
          ;
        } else {
          return callback(null, value);
        }
      }, this));
    };
    RedisFs.prototype.set = function(key, value, callback) {
      return this.redis.set(key, value, __bind(function(err, reply) {
        if (err != null) {
          return callback(err);
        } else {
          return callback(null, {
            key: key,
            reply: reply
          });
        }
      }, this));
    };
    RedisFs.prototype.open = function(key, encoding, callback) {
      return temp.open('redisfs', __bind(function(err, file) {
        if (err != null) {
          return callback(err);
        } else {
          return this.redis2file(key, {
            filename: file.path,
            encoding: encoding
          }, callback);
        }
      }, this));
    };
    RedisFs.prototype.write = function(filename, value, encoding, callback) {
      return fs.writeFile(filename, value, encoding, __bind(function(err) {
        if (err != null) {
          return callback(err);
        } else {
          return callback(null, filename);
        }
      }, this));
    };
    return RedisFs;
  })();
  connectToRedis = function(options) {
    return redis.createClient(options.port, options.host);
  };
  exports.RedisFs = RedisFs;
}).call(this);
