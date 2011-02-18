fs   = require 'fs'
temp = require 'temp'

# creates a file fixture
exports.setup = (callback) ->
  temp.open {prefix: 'redisfs-test-', suffix: '.txt'}, (err, file) ->
    if err? then callback err else write file.path, callback    

# write a file
write = (file, callback) ->
  fs.writeFile file, 'test', (err) ->
    if err? then callback err else callback null, file

