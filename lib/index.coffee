exports.version = "0.1.0"

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
  new exports.RedisFs options or {}

# 
# Dependencies
#
_    = require 'underscore'
fs   = require 'fs'
uuid = require 'node-uuid'
temp = require 'temp'

#
# Util to pump files in and out of redis.  
#
class RedisFs
  constructor: (@redis = redis.createClient(), @keys[]) ->
    @redis      = options.redis or connectToRedis options
    @namespace ?= 'redisfs'
    @redis.select options.database if options.database?
    
  #
  # pumps a file contents into a redis key.  takes a config hash:
  #  - filename -> the full path to the file to consume
  #  - key      -> optional redis key.  if omitted a uuid will be 
  #                generated.
  #  - encoding -> optional file encoding, defaults to utf8.
  #  - callback -> recieves either an error as the first param 
  #                or success hash that contains the key and reply
  #                as the second param.
  #
  file2redis: (config) ->
    key      = config.key or uuid()
    filename = config.filename
    callback = config.callback
    encoding = encoding or 'utf8'
    @keys.push key unless config.key
    fs.readFile filename, encoding, (err, data) =>
      if err? then callback err else @set key, data, callback

  #
  # pumps a redis value to a file. takes the following config hash
  #  - key      -> the redis key to fetch the value from
  #  - filename -> optional filename to write to.  if ommitted
  #                a temp file will be generated.
  #  - encoding -> optional file encoding, defaults to utf8
  #  - callback -> receives the and error as the first param
  #                or a success hash that contains the path
  #                and a fd to the file
  #
  redis2file: (config) ->
    key      = config.key
    callback = config.callback
    encoding = encoding or 'utf8'    
    @get key, (err, value) =>
      if err callback err else write filename, value, encoding, callback

  #
  # @private
  # gets the value of the key.  callback will receive the value.
  #
  get: (key, callback) ->
    @redis.get key, (err, value) =>
      throw err if err?
      callback value

  # 
  # private:
  # sets the value to a new redis key.  callback will
  # receive the new key and the redis reply.
  #
  set: (key, value, callback) ->
    @redis.set key, value, (err, reply) =>
      if err callback err else callback null, {key: key, reply: reply}

  #
  # @private
  # pumps a redis value into a generated temp file. callback will
  # receive the filename
  #
  open: (key, callback) ->
    temp.open 'redisfs', (err, file) =>
      if err then callback err else @redis2file key, file.path, callback

  #
  # @private
  # write to a file
  #
  write: (filename, value, encoding, callback) -> 
    fs.writeFile filename, value, encoding, (err) =>
      if err then callback err else callback filename
  
  #
  # end the redis connection and del all the keys generated during
  # the session (defaults to false).
  #
  end: (cleanup = false) ->
    if cleanup
      multi = @redis.multi() 
      multi.del key for key in @keys
      multi.exec (err, replies) =>
        console.log "Unable to del all generated keys #{JSON.stringify replies}"
        @redis.quit()
    else
      @redis.quit()

#
# fetch a redis client
#     
connectToRedis = (options) ->
  require('redis').createClient options.port, options.host

exports.RedisFs = RedisFs
