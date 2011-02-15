vows      = require 'vows'
assert    = require 'assert'
{redisfs} = require '../src/index.coffee'

fixture  = redisfs()
redis    = fixture.redis

vows.describe('end').addBatch(
  ##################################################
  'end and cleanup of generated keys':
    topic: -> fixture.file2redis 'test/fixture-file.txt', @callback
    'create a key to test': (err, result) ->
      assert.ok result.key?
    'deletes generated key from redis': 
      topic: (result) -> fixture.end true, @callback
      'expecting a single key to be deleted': (err, result) ->
        assert.equal '1', result
    teardown: -> redis.flushdb()

).export module
