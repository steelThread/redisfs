vows      = require 'vows'
assert    = require 'assert'
{redisfs} = require '../lib/index.coffee'

fixture = require('redis').createClient()

vows.describe('RedisFs').addBatch(
  ##################################################
  'construct with defaults': 
    topic: redisfs(),
    'exists': (redisfs) -> 
      assert.ok redisfs?
    'connected to redis': (redisfs) -> 
      assert.ok redisfs.redis?
    'redisfs is the namespace': (redisfs) -> 
      assert.equal 'redisfs', redisfs.namespace

  ###################################################
  'construct with options':
    topic: redisfs(redis: fixture, namespace: 'test')
    'namespace is test': (redisfs) ->
      assert.equal 'test', redisfs.namespace
    'uses existing redis connection': (redisfs) ->
      assert.equal fixture, redisfs.redis

).export module