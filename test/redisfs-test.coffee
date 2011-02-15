fs        = require 'fs'
vows      = require 'vows'
redis     = require 'redis'
assert    = require 'assert'
{redisfs} = require '../src/index.coffee'

client   = redis.createClient()
fixture  = redisfs()

# start clean
client.flushdb()

vows.describe('RedisFs').addBatch(
  ##################################################
  'construct with defaults':
    topic: fixture,
    'works': (redisfs) ->
      assert.ok redisfs?
    'connects to redis': (redisfs) ->
      assert.ok redisfs.redis?
    'uses redisfs as the namespace': (redisfs) ->
      assert.equal 'redisfs', redisfs.namespace

  ###################################################
  'construct with options':
    topic: redisfs(redis: client, namespace: 'test')
    'uses passed namespace option': (redisfs) ->
      assert.equal 'test', redisfs.namespace
    'uses passed redis client option': (redisfs) ->
      assert.equal client, redisfs.redis

  ###################################################
  'file2redis with defaults':
    topic: -> fixture.file2redis 'test/fixture-file.txt', @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the generated key to the callback': (err, result) ->
      assert.ok result.key?
    'sets key with file contents':
      topic: (result) -> client.get result.key, @callback
      'value should be test': (err, result) ->
        assert.equal 'test', result
      teardown: (result) -> client.flushdb()

  ###################################################
  'file2redis with passed key option':
    topic: -> fixture.file2redis 'test/fixture-file.txt', {key: 'test'}, @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the key to the callback': (err, result) ->
      assert.equal 'test', result.key
    'sets key with file contents':
      topic: (result) -> client.get 'test', @callback
      'value should be test': (err, result) ->
        assert.equal 'test', result
      teardown: -> client.flushdb()
  
  ###################################################
  'file2redis with passed encoding':
    topic: -> fixture.file2redis 'test/fixture-file.txt', {encoding: 'base64'}, @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the generated key to the callback': (err, result) ->
      assert.ok result.key?
    'key contains the base 64 encoded file contents':
      topic: (result) -> client.get result.key, @callback
      'sets key with base64 encoded file contents': (err, result) ->
        assert.equal result, new Buffer('test', "ascii").toString('base64')
      teardown: -> client.flushdb()
  
  ###################################################
  'file2redis with passed key and encoding':
    topic: -> fixture.file2redis 'test/fixture-file.txt', {key: 'testtoo', encoding: 'base64'}, @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the key to the callback': (err, result) ->
      assert.equal 'testtoo', result.key
    'key contains the base 64 encoded file contents':
      topic: (result) -> client.get 'testtoo', @callback
      'should be test base64 encoded': (err, result) ->
        assert.equal result, new Buffer('test', "ascii").toString('base64')
      teardown: -> client.flushdb()
  
  ###################################################
  'redis2file with defaults':
    topic: -> fixture.file2redis 'test/fixture-file.txt', @callback
    'generates a key': (err, result) ->
      assert.equal 'OK', result.reply
    'writes to a temp file':
      topic: (result) -> fixture.redis2file result.key, @callback
      'contents of resulting file':
        topic: (result) -> fs.readFile result, 'utf8', @callback
        'should be test': (data) ->
          assert.equal 'test', data
        teardown: (result) -> client.flushdb()

  # ##################################################
  # 'end':
  #   topic: -> fixture.file2redis './fixture-file.txt', @callback
  #   'returns the generated key to the callback': (err, result) ->
  #     assert.ok result.key?
  #   'deletes generated key': 
  #     topic: (result) -> fixture.end true, @callback
  #     'replies with 1,1,1': (err, result) ->
  #       assert.equal '1,1,1', result
  #     teardown: -> client.flushdb()

).export module
