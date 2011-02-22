vows      = require 'vows'
assert    = require 'assert'
{setup}   = require './helper'
{redis}   = require './helper'
{redisfs} = require '../src/index.coffee'
{teardown} = require './helper'

redisfs = redisfs()

vows.describe('cleanup').addBatch(
  ##################################################
  'cleanup generated keys and files by default':
    topic: -> setup (err, file) => redisfs.file2redis file, @callback
    'create a key to test': (err, result) ->
      assert.ok result.key?
    'on end':
      topic: (result) ->
        redisfs.end()
        redis.exists result.key, @callback
      'key is deleted from redis': (err, result) ->
        assert.equal '0', result
      'key is no longer being tracked': (err, result) ->
        assert.equal '0', redisfs.keys.length
    teardown: -> teardown()

).export module
