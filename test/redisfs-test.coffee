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
    topic: -> topic.file2redis './fixture-file.txt', @callback
    'reply was OK': (err, result) ->
      assert.equal 'OK', result.reply
    'gets back a key': (err, result) ->
      assert.ok result.key?
    'key contains the files contents': 
      topic: (result) -> client.get result.key, @callback
      'should be test': (err, result) ->
        assert.equal 'test', result
      teardown: (result) -> client.flushdb()

  ###################################################
  'file2redis with passed key':
    topic: -> topic.file2redis './fixture-file.txt', {key: 'test'}, @callback
    'reply was OK': (err, result) ->
      assert.equal 'OK', result.reply
    'gets back the passed key': (err, result) ->
      assert.equal 'test', result.key
    'key contains the files contents': 
      topic: (result) -> client.get 'test', @callback
      'should be test': (err, result) ->
        assert.equal 'test', result
      teardown: -> client.flushdb()

  ###################################################
  'file2redis with passed encoding':
    topic: -> topic.file2redis './fixture-file.txt', {encoding: 'base64'}, @callback
    'reply was OK': (err, result) ->
      assert.equal 'OK', result.reply
    'gets back a key': (err, result) ->
      assert.ok result.key?
    'key contains the files contents': 
      topic: (result) -> client.get result.key, @callback
      'should be test base64 encoded': (err, result) ->
        assert.equal result, new Buffer('test', "ascii").toString('base64')
      teardown: -> client.flushdb()

  ###################################################
  'file2redis with passed key and encoding':
    topic: -> topic.file2redis './fixture-file.txt', {key: 'testtoo', encoding: 'base64'}, @callback
    'reply was OK': (err, result) ->
      assert.equal 'OK', result.reply
    'gets back the passed key': (err, result) ->
      assert.equal 'testtoo', result.key
    'key contains the files contents': 
      topic: (result) -> client.get 'testtoo', @callback
      'should be test base64 encoded': (err, result) ->
        assert.equal result, new Buffer('test', "ascii").toString('base64')
      teardown: -> client.flushdb()

).export module