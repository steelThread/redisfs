vows      = require 'vows'
assert    = require 'assert'
{setup}   = require './helper'
{redis}   = require './helper'
{redisfs} = require '../src/index.coffee'
{teardown} = require './helper'

redisfs = redisfs()

vows.describe('end').addBatch(
  ##################################################
  'end will cleanup generated keys by default':
    topic: -> setup (err, file) => redisfs.file2redis file, @callback
    'create a key to test': (err, result) ->
      assert.ok result.key?
    'on end': 
      topic: (result) -> 
        redisfs.end()
        redis.exists result.key, @callback
      'key is deleted from redis': (err, result) ->
        assert.equal '0', result
      'key tracking array is emptied': (err, result) ->
        assert.equal '0', redisfs.keys.length
    teardown: -> teardown()

).export module
