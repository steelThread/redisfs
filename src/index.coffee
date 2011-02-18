exports.version = '0.1.0'

#
# Sets up a new RedisFs instance.  Generated files and keys
# are tracked so that they can be requested to be deleted at a
# later time via the cleanup of end methods.
#
# options - Optional Hash of options.
#   redis        - Existing instance of node_client.
#   host         - String Redis host.  (Default: Redis' default)
#   port         - Integer Redis port.  (Default: Redis' default)
#   namespace    - String namespace prefix for generated Redis keys.
#                  (Default: redisfs).
#   database     - Optional Integer of the Redis database to select.
#   *dir         - Optional path to write files out to for generated files.
#                 (Default: your systems temporary directory)
#   *prefix     - Optional prefix to use for generated files.  (Default: 'redisfs')
#   *suffix     - Optional suffix to use for generated files. 
#   *deleteKey  - Optional boolean to indicate if the key should be
#                 deleted on a redis2file operation.  (Default: true)
#   *deleteFile - Optional boolean to indicate if the file should be
#                 deleted on a file2redis operation.  (Default: true)
#
# Note: all params marked as * represent future implementations
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
  constructor: (options = {}, @keys = [], @files = []) ->
    @redis      = options.redis or connectToRedis options
    @namespace  = options.namespace or 'redisfs'
    @redis.select options.database if options.database?

  #
  # Pumps a file's contents into a redis key and deletes the file. 
  #   filename   - The full path to the file to consume
  #   options    - 
  #     key      - Optional redis key.  If omitted a key will be 
  #                generated using a uuid.
  #     encoding - Optional file encoding, defaults to utf8.
  #   deleteFile - Optional boolean to indicate whether the file file
  #                should be deleted after it is pumped into redis.
  #                (Default: false)
  #   callback   - Recieves either an error as the first param
  #                or success hash that contains the key and reply
  #                as the second param.
  #
  file2redis: (filename, options, callback) ->
    if _.isFunction options
      callback = options
      options  = {}
    key = options.key or "#{@namespace}:#{uuid()}"
    encoding = options.encoding or 'utf8'
    @keys.push key unless options.key
    fs.readFile filename, encoding, (err, data) =>
      if err? then callback err 
      else 
        @set key, data, callback
        @deleteFiles [filename]

  #
  # Pumps a redis value to a file and deletes the redis key.
  #   key          - The redis key to fetch.
  #   options
  #     filename   - Optional filename to write to. assumes the file is
  #                  preexisting and writable.  If ommitted a temp file 
  #                  will be generated.
  #     encoding   - Optional file encoding, defaults to utf8
  #                  This overrides the instance level options if specified.
  #     *dir       - Optional path to write files out to for generated files.
  #                  This overrides the instance level options if specified.
  #     *prefix    - Optional prefix to use for generated files.
  #                  This overrides the instance level options if specified.
  #     *suffix    - Optional suffix to use for generated files. 
  #                  This overrides the instance level options if specified.
  #     *deleteKey - Optional boolean to indicate if the key should be
  #                  removed after the get operation.  (Default: to value
  #                  set on instance)
  #   callback     - Receives the and error as the first param
  #                  or a success hash that contains the path
  #                  and a fd to the file.
  #
  # Note: all params marked as * represent future implementations
  #
  redis2file: (key, options, callback) ->
    if _.isFunction options
      callback = options
      options  = {}
    encoding = options.encoding or 'utf8'
    if options.filename?
      @get key, (err, value) =>
        if err? then callback err 
        else
          @write options.filename, value, encoding, callback
          @deleteKeys [key] 
    else
      @open key, encoding, callback

  #
  # Delete generated resources.
  #   options - Optional object indicating which generated resources to 
  #             delete (keys and/or files). Omission of options will result
  #             in the deletion of both files and keys.
  #     files - Optional boolean indicating whether generated files 
  #             should be deleted.
  #     keys  - Optional boolean indicating whether files should be
  #             deleted.
  #
  cleanup: (options) ->
    both   = on unless options?
    both or= options?.keys and options?.files
    keys   = if both then on else options?.keys  or off
    files  = if both then on else options?.files or off

    @deleteKeys  if keys
    @deleteFiles if files

  #
  # End the redis connection and deletes all the generated during
  # the session.  Pass true as the first argument to cleanup the
  # generated keys and files with an optional callback.  Callback is not
  # invoked unless cleanup is requested.
  #
  end: (cleanup, callback) ->
    callback = cleanup if _.isFunction cleanup
    if cleanup is on
      multi = @redis.multi()
      multi.del key for key in @keys
      multi.exec (err, replies) =>
        log "Unable to del all generated keys #{JSON.stringify replies}" if err?
        callback(err, replies) if callback?
        @redis.quit()
    else
      @redis.quit()

  #
  # @private
  # Fets the value of the key.  Callback will be passed the value.
  #
  get: (key, callback) ->
    @redis.get key, (err, value) =>
      if err? callback err else callback null, value

  #
  # @private
  # Sets the value to a new redis key.  Callback will be passed
  # a result object containing the key and the redis reply.
  #
  set: (key, value, callback) ->
    @redis.set key, value, (err, reply) =>
      if err? then callback err else callback null, {key: key, reply: reply}

  #
  # @private
  # Pumps a redis value into a generated temp file. Callback will
  # receive the filename.
  #
  open: (key, encoding, callback) ->
    temp.open 'redisfs', (err, file) =>
      if err? then callback err
      else
        @files.push file.path
        @redis2file key, {filename: file.path, encoding: encoding}, callback

  #
  # @private
  # Write to a file
  #
  write: (filename, value, encoding, callback) ->
    fs.writeFile filename, value, encoding, (err) =>
      if err? then callback err else callback null, filename

  #
  # @private
  # Delete all the generated keys in a multi op.  Errors are ignored.
  #
  deleteKeys: (keys = @fkeys) ->
    multi = @redis.multi()
    multi.del key for key in keys
    multi.exec()
    keys = []
    
  #
  # @private
  # Delete all the generated files.  Errors are ignored.
  #
  deleteFiles: (files = @files)->
    fs.unlink file for file in files
    files = []

#
# fetch a redis client
#
connectToRedis = (options) ->
  redis.createClient options.port, options.host

exports.RedisFs = RedisFs
