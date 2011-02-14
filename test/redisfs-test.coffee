vows      = require 'vows'
redis     = require 'redis'
assert    = require 'assert'
{redisfs} = require '../lib/index.coffee'

topic  = redisfs()
client = redis.createClient()

# start clean
client.flushdb()

vows.describe('RedisFs').addBatch(
  ##################################################
  'construct with defaults': 
    topic: topic,
    'exists': (redisfs) -> 
      assert.ok redisfs?
    'connected to redis': (redisfs) -> 
      assert.ok redisfs.redis?
    'redisfs is the namespace': (redisfs) -> 
      assert.equal 'redisfs', redisfs.namespace

  ###################################################
  'construct with options':
    topic: redisfs(redis: client, namespace: 'test')
    'namespace is test': (redisfs) ->
      assert.equal 'test', redisfs.namespace
    'uses existing redis connection': (redisfs) ->
      assert.equal client, redisfs.redis
  
  ###################################################
  'file2redis with defaults':
    topic: -> topic.file2redis(filename: './fixture-file.txt', callback: @callback)
    'gets back a key': (err, result) ->
      assert.ok result.key?
    'reply was OK': (err, result) ->
      assert.equal 'OK', result.reply
    'key contains the files contents': 
      topic: (result) -> client.get(result.key, @callback)
      'should be test': (err, result) ->
        assert.equal 'test', result

).export module