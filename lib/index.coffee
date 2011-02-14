exports.version = '0.1.0'

#
# Sets up a new RedisFs instance.  
#
# options - Optional Hash of options.
#   redis     - Existing instance of node_client.
#   host      - String Redis host.  (Default: Redis' default)
#   port      - Integer Redis port.  (Default: Redis' default)
#   namespace - String namespace prefix for generated Redis keys.  
#               (Default: redisfs).
#   database  - Optional Integer of the Redis database to select.
#   dir       - Optional path to write files out to.
#           
exports.redisfs = (options) ->
  new exports.RedisFs options

# 
# Dependencies
#
_     = require 'underscore'
fs    = require 'fs'
temp  = require 'temp'
uuid  = require 'node-uuid'
redis = require 'redis'
log   = console.log

#
# Util to pump files in & out of redis.  
#
class RedisFs
  constructor: (options = {}, @keys = []) ->
    @redis      = options.redis or connectToRedis options
    @namespace  = options.namespace or 'redisfs'
    @redis.select options.database if options.database?
    
  #
  # pumps a file's contents into a redis key.  takes a arg hash:
  #  - filename -> the full path to the file to consume
  #  - options  -> optional object with 2 members
  #      key:      optional redis key.  if omitted a uuid will be generated.
  #      encoding: optional file encoding, defaults to utf8.
  #  - callback -> recieves either an error as the first param 
  #                or success hash that contains the key and reply
  #                as the second param.
  #
  file2redis: (filename, options, callback) ->
    if _.isFunction options
      console.log 'options is the callback'
      callback = options
      options = {}
    key = options.key or "#{@namespace}:#{uuid()}"
    encoding = options.encoding or 'utf8'    
    @keys.push key unless options.key
    fs.readFile filename, encoding, (err, data) =>
      if err? then callback err else @set key, data, callback

  # #
  # # pumps a redis value to a file. takes the following config hash
  # #  - key      -> the redis key to fetch the value from
  # #  - options  -> optional object with 2 members
  # #   filename:    optional filename to write to.  if ommitted
  # #                a temp file will be generated.
  # #   encoding:    optional file encoding, defaults to utf8
  # #  - callback -> receives the and error as the first param
  # #                or a success hash that contains the path
  # #                and a fd to the file
  # #
  # redis2file: (key, options, callback) ->
  #   if _.isFunction options
  #     callback = options
  #     options = {}
  #   filename = options.filename or 'temp' # fix this
  #   encoding = options.encoding or 'utf8'    
  #   @get key, (err, value) =>
  #     if err? then callback err else write filename, value, encoding, callback

  #
  # end the redis connection and del all the keys generated during
  # the session (defaults to false).
  #
  end: (cleanup = false) ->
    if cleanup
      multi = @redis.multi() 
      multi.del key for key in @keys
      multi.exec (err, replies) =>
        log "Unable to del all generated keys #{JSON.stringify replies}" if err?
        @redis.quit()
    else
      @redis.quit()

  # #
  # # @private
  # # gets the value of the key.  callback will receive the value.
  # #
  # get: (key, callback) ->
  #   @redis.get key, (err, value) =>
  #     if err? callback err else callback null, value
  # 
  # 

  # @private
  # sets the value to a new redis key.  callback will
  # receive the new key and the redis reply.
  #
  set: (key, value, callback) ->
    @redis.set key, value, (err, reply) =>
      if err? then callback err else callback null, {key: key, reply: reply}

  # #
  # # @private
  # # pumps a redis value into a generated temp file. callback will
  # # receive the filename
  # #
  # open: (key, callback) ->
  #   temp.open 'redisfs', (err, file) =>
  #     if err? then callback err else @redis2file key, file.path, callback
  # 
  # #
  # # @private
  # # write to a file
  # #
  # write: (filename, value, encoding, callback) -> 
  #   fs.writeFile filename, value, encoding, (err) =>
  #     if err? then callback err else callback filename
  
#
# fetch a redis client
#     
connectToRedis = (options) ->
  redis.createClient options.port, options.host

exports.RedisFs = RedisFs
