vows      = require 'vows'
assert    = require 'assert'
{setup}   = require './helper'
{redisfs} = require '../src/index.coffee'


fixture  = redisfs()

# start clean
redis = fixture.redis
redis.flushdb()

vows.describe('end').addBatch(
  ##################################################
  'end and cleanup of generated keys':
    topic: -> setup (err, file) => fixture.file2redis file, @callback
    'create a key to test': (err, result) ->
      assert.ok result.key?
    'deletes generated key from redis': 
      topic: (result) -> fixture.end true, @callback
      'expecting a single key to be deleted': (err, result) ->
        assert.equal '1', result
    teardown: -> redis.flushdb()

).export module
