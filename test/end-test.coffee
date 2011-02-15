vows      = require 'vows'
assert    = require 'assert'
{redisfs} = require '../src/index.coffee'

fixture  = redisfs()
redis    = fixture.redis

vows.describe('end').addBatch(
  ##################################################
  'end and cleanup':
    topic: -> fixture.file2redis 'test/fixture-file.txt', @callback
    'returns the generated key to the callback': (err, result) ->
      assert.ok result.key?
    'deletes generated key from redis': 
      topic: (result) -> fixture.end true, @callback
      'replies with 1': (err, result) ->
        assert.equal '1', result
    teardown: -> redis.flushdb()

).export module
