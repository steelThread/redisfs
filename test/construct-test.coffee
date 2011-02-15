fs        = require 'fs'
vows      = require 'vows'
redis     = require 'redis'
assert    = require 'assert'
{redisfs} = require '../src/index.coffee'

fixture  = redisfs()

vows.describe('construct').addBatch(
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
    topic: redisfs(redis: 'test', namespace: 'test')
    'uses passed namespace option': (redisfs) ->
      assert.equal 'test', redisfs.namespace
    'uses passed redis client option': (redisfs) ->
      assert.equal 'test', redisfs.redis

).export module
