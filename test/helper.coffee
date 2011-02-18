fs    = require 'fs'
temp  = require 'temp'
redis = require('redis').createClient()

# redis connection
exports.redis = redis

# creates a file fixture
exports.setup = (callback) ->
  temp.open {prefix: 'redisfs-test-', suffix: '.txt'}, (err, file) ->
    if err? then callback err else write file.path, callback    

# flush redis
exports.teardown = -> redis.flushdb()

# write a file
write = (file, callback) ->
  fs.writeFile file, 'test', (err) ->
    if err? then callback err else callback null, file

