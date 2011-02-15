vows      = require 'vows'
assert    = require 'assert'
{redisfs} = require '../src/index.coffee'

fixture  = redisfs()

# start clean
redis = fixture.redis
redis.flushdb()

vows.describe('file2redis').addBatch(
  ###################################################
  'file2redis with defaults':
    topic: -> fixture.file2redis 'test/fixture-file.txt', @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the generated key to the callback': (err, result) ->
      assert.ok result.key?
    'sets key with file contents':
      topic: (result) -> redis.get result.key, @callback
      'value should be test': (err, result) ->
        assert.equal 'test', result
    teardown: (result) -> redis.flushdb()

  ###################################################
  'file2redis with passed key option':
    topic: -> fixture.file2redis 'test/fixture-file.txt', {key: 'test'}, @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the key to the callback': (err, result) ->
      assert.equal 'test', result.key
    'sets key with file contents':
      topic: (result) -> redis.get 'test', @callback
      'value should be test': (err, result) ->
        assert.equal 'test', result
    teardown: -> redis.flushdb()

  ###################################################
  'file2redis with passed encoding':
    topic: -> fixture.file2redis 'test/fixture-file.txt', {encoding: 'base64'}, @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the generated key to the callback': (err, result) ->
      assert.ok result.key?
    'key contains the base 64 encoded file contents':
      topic: (result) -> redis.get result.key, @callback
      'sets key with base64 encoded file contents': (err, result) ->
        assert.equal result, new Buffer('test', "ascii").toString('base64')
    teardown: -> redis.flushdb()

  ###################################################
  'file2redis with passed key and encoding':
    topic: -> fixture.file2redis 'test/fixture-file.txt', {key: 'testtoo', encoding: 'base64'}, @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the key to the callback': (err, result) ->
      assert.equal 'testtoo', result.key
    'key contains the base 64 encoded file contents':
      topic: (result) -> redis.get 'testtoo', @callback
      'should be test base64 encoded': (err, result) ->
        assert.equal result, new Buffer('test', "ascii").toString('base64')
    teardown: -> redis.flushdb()

).export module

