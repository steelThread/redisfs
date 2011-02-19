vows      = require 'vows'
assert    = require 'assert'
{redisfs} = require '../src/index.coffee'

vows.describe('construct').addBatch(
  ##################################################
  'construct with defaults':
    topic: -> redisfs(),
    'works': (redisfs) ->
      assert.ok redisfs?
    'connects to redis': (redisfs) ->
      assert.ok redisfs.redis?
    'uses redisfs as the namespace': (redisfs) ->
      assert.equal redisfs.config.namespace, 'redisfs'
    'uses passed prefix': (redisfs) ->
      assert.equal redisfs.config.prefix, 'redisfs-'
    'uses passed encoding': (redisfs) ->
      assert.equal redisfs.config.encoding, 'utf8'

  ####################################################
  'construct with options':
    topic: -> redisfs(redis: 'test', namespace: 'ns', prefix: 'prefix', suffix: 'suffix', encoding: 'encoding')
    'uses passed namespace': (topic) ->
      assert.equal topic.config.namespace, 'ns'
    'uses passed redis client': (topic) ->
      assert.equal topic.redis, 'test' 
    'uses passed prefix': (topic) ->
      assert.equal topic.config.prefix, 'prefix'
    'uses passed suffix': (topic) ->
      assert.equal topic.config.suffix, 'suffix'
    'uses passed encoding': (topic) ->
      assert.equal topic.config.encoding, 'encoding'

).export module
