fs        = require 'fs'
vows      = require 'vows'
assert    = require 'assert'
{setup}    = require './helper'
{redisfs} = require '../src/index.coffee'
{teardown} = require './helper'

redisfs  = redisfs()

vows.describe('redis2file').addBatch(
  ###################################################
  'redis2file with defaults':
    topic: -> setup (err, file) => redisfs.file2redis file, @callback
    'generates a file': (err, result) ->
      assert.equal 'OK', result.reply
    'writes to a temp file':
      topic: (result) -> redisfs.redis2file result.key, @callback
      'records the generated file': (err, result) ->
        assert.ok redisfs.files.indexOf result.result is not -1
      'contents of resulting file':
        topic: (result) -> fs.readFile result, 'utf8', @callback
        'should be test': (data) ->
          assert.equal 'test', data
    teardown: (result) -> teardown()

).export module

