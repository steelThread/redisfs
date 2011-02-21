#!/usr/bin/env coffee

coffee         = require 'coffee-script'
redisfs        = require '../src/index'
{OptionParser} = require 'coffee-script/optparse'

log = console.log

require.extensions['.coffee'] = (module, filename) ->
   content = coffee.compile fs.readFileSync filename, 'utf8'
   module._compile content, filename

usage = '''
  Usage:
    file2redis [OPTIONS] path
'''

switches = [
  ['-h', '--help', 'Displays options']
  ['-v', '--version', "Shows file2redis' version."]
  ['-k', '--key [STRING]', "The key to set. (Defaults: generated key)"]
  ['-e', '--encoding [STRING]', "The encoding to use. (Defaults: utf8)"]
  ['-d', '--deleteFile', "Indicator to delete the file after the op. (Defaults: false)"]
]

argv = process.argv[2..]
parser = new OptionParser switches, usage
options = parser.parse argv
args = options.arguments
delete options.arguments

if args.length is 0 and argv.length is 0
  log parser.help()
  log "v#{redisfs.version}"

log parser.help() if options.help
log "v#{redisfs.version}" if options.version
if args[0]
  redisfs = redisfs.redisfs
    key: options.key if options.key? 
    encoding: options.encoding if options.encoding?
    deleteFile: options.deleteFile or off

  redisfs.file2redis args[0], (err, result) ->
    if err? then log "error: #{err}" else log "#{result.reply}  key -> #{result.key}"
    redisfs.end false
