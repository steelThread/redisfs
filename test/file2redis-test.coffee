fs         = require 'fs'
temp       = require 'temp'
vows       = require 'vows'
assert     = require 'assert'
{setup}    = require './helper'
{redis}    = require './helper'
{redisfs}  = require '../src/index.coffee'
{teardown} = require './helper'

redisfs  = redisfs()

vows.describe('file2redis').addBatch(
  ###################################################
  'file2redis with defaults':
    topic: -> setup (err, file) => redisfs.file2redis file, @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the generated key to the callback': (err, result) ->
      assert.ok result.key?
    'records the generated key': (err, result) ->
      assert.ok redisfs.keys.indexOf result.keys is not -1
    'sets key with file contents':
      topic: (result) -> redis.get result.key, @callback
      'value should be test': (err, result) ->
        assert.equal 'test', result
    teardown: -> teardown()

  ###################################################
  'file2redis with passed key option':
    topic: -> setup (err, file) => redisfs.file2redis file, {key: 'test'}, @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the key to the callback': (err, result) ->
      assert.equal 'test', result.key
    'doesnt record the generated key': (err, result) ->
      assert.ok redisfs.keys.indexOf result.keys is -1
    'sets key with file contents':
      topic: (result) -> redis.get 'test', @callback
      'value should be test': (err, result) ->
        assert.equal 'test', result
    teardown: -> teardown()

  ###################################################
  'file2redis with passed encoding':
    topic: -> setup (err, file) => redisfs.file2redis file, {encoding: 'base64'}, @callback
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
  'file2redis with passed expiration':
    topic: -> setup (err, file) => redisfs.file2redis file, {expire: 3}, @callback
    'key set in redis': (err, result) ->
      assert.equal 'OK', result.reply
    'returns the generated key to the callback': (err, result) ->
      assert.ok result.key?
    'key has time to live':
      topic: (result) -> redis.ttl result.key, @callback
      'sets key with expire': (err, result) ->
        assert.ok result isnt -1
    teardown: -> teardown()

  ###################################################
  'file2redis with passed key and encoding':
    topic: -> setup (err, file) => redisfs.file2redis file, {key: 'testtoo', encoding: 'base64'}, @callback
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

