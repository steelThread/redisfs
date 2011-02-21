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
    redis2file [OPTIONS] key
'''

switches = [
  ['-h', '--help', 'Displays options']
  ['-v', '--version', "Shows file2redis' version."]
  ['-f', '--file', "The path of the file to write to. (Defaults: generated temp file)"]
  ['-e', '--encoding', "The encoding to use. (Defaults: utf8)"]
  ['-d', '--delete', "Indicator to delete the key after the op. (Defaults: true)"]
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
#mimeograph.start args[0] if args[0]