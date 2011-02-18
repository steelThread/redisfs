fs         = require 'fs'
temp       = require 'temp'
vows       = require 'vows'
assert     = require 'assert'
{setup}    = require './helper'
{redisfs}  = require '../src/index.coffee'

fixture  = redisfs()

# start clean
redis = fixture.redis
teardown = -> redis.flushdb()
teardown()

vows.describe('file2redis').addBatch(
  ###################################################
  'file2redis with defaults':
    topic: -> setup (err, file) => fixture.file2redis file, @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the generated key to the callback': (err, result) ->
      assert.ok result.key?
    'sets key with file contents':
      topic: (result) -> redis.get result.key, @callback
      'value should be test': (err, result) ->
        assert.equal 'test', result
    teardown: -> teardown()

  ###################################################
  'file2redis with passed key option':
    topic: -> setup (err, file) => fixture.file2redis file, {key: 'test'}, @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the key to the callback': (err, result) ->
      assert.equal 'test', result.key
    'sets key with file contents':
      topic: (result) -> redis.get 'test', @callback
      'value should be test': (err, result) ->
        assert.equal 'test', result
    teardown: -> teardown()

  ###################################################
  'file2redis with passed encoding':
    topic: -> setup (err, file) => fixture.file2redis file, {encoding: 'base64'}, @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the generated key to the callback': (err, result) ->
      assert.ok result.key?
    'key contains the base 64 encoded file contents':
      topic: (result) -> redis.get result.key, @callback
      'sets key with base64 encoded file contents': (err, result) ->
        assert.equal result, new Buffer('test', "ascii").toString('base64')
    teardown: -> teardown()

  ###################################################
  'file2redis with passed key and encoding':
    topic: -> setup (err, file) => fixture.file2redis file, {key: 'testtoo', encoding: 'base64'}, @callback
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

