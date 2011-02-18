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

DEFAULTS = 
  deleteKey:  true
  deleteFile: true
  encoding:   'utf8'
  namespace:  'redisfs'
  prefix:     'redisfs-'

#
# Util to pump files in & out of redis.  
#
class RedisFs
  constructor: (options = {}, @keys = [], @files = []) ->
    _.extend @, _.extend DEFAULTS, options
    @redis      = options.redis or connectToRedis options
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
  #                (Default: true)
  #   callback   - Recieves either an error as the first param
  #                or success hash that contains the key and reply
  #                as the second param.
  #
  file2redis: (filename, options, callback) ->
    if _.isFunction options
      callback = options
      options  = {}
    key = options.key or "#{@namespace}:#{uuid()}"
    encoding = options.encoding or @encoding
    @keys.push key unless options.key
    fs.readFile filename, encoding, (err, data) =>
      if err? then callback err 
      else 
        @set key, data, callback
        @deleteFiles [_.pop @files, filename]

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
    encoding = options.encoding or @encoding
    if options.filename?
      @get key, (err, value) =>
        if err? then callback err 
        else
          @write options.filename, value, encoding, callback
          @deleteKeys [_.pop @keys, key] 
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

    @deleteKeys()  if keys
    @deleteFiles() if files

  #
  # End the redis connection and deletes all the resources generated during
  # the session.  
  #  options - Optional object see cleanup.  Omission of this will result in both
  #            generated keys and files will be deleted. Passing a false
  #            will prevent any deletiion
  #
  end: (options) ->
    @cleanup options unless options is off
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
  deleteKeys: (keys = @keys) ->
    multi = @redis.multi()
    multi.del key for key in keys
    multi.exec()
    @keys = [] if @keys is keys
    
  #
  # @private
  # Delete all the generated files.  Errors are ignored.
  #
  deleteFiles: (files = @files) ->
    fs.unlink file for file in files
    @files = [] if @files is files

#
# fetch a redis client
#
connectToRedis = (options) ->
  redis.createClient options.port, options.host

#
# Pops any element on an array.
#
_.mixin
  pop: (array, value) ->
    index = array.indexOf value
    if index
      swap = array.pop()
      array[index] = swap unless swap is value
    value

exports.RedisFs = RedisFs
