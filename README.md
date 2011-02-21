		              _ _      __     
		 _ __ ___  __| (_)___ / _|___ 
		| '__/ _ \/ _` | / __| |_/ __|
		| | |  __/ (_| | \__ \  _\__ \
		|_|  \___|\__,_|_|___/_| |___/


# About
RedisFs is a dead simple utility for moving files in and out of Redis.  

# Installing
	$ npm install redisfs
 
# Usage
There are two ways to use redisfs via the command line interface or programmatically
in your node scripts.

## Using redisfs from the command line.
### file2redis
	Usage:
	  file2redis [OPTIONS] path

	Available options:
	  -h, --help         Displays options
	  -v, --version      Shows file2redis' version.
	  -k, --key          The key to set. (Defaults: generated key)
	  -e, --encoding     The encoding to use. (Defaults: utf8)
	  -d, --deleteFile   Indicator to delete the file after the op. (Defaults: false)
    
    $  file2redis -e base64 /some/path/to/a/file
    >> OK  key -> redisfs:F246C436-B004-4218-B8AA-7766C6E0C604

    $  file2redis -k my:key -d /some/path/to/a/file  
    >> OK  key -> my:key

### redis2file
	Usage:
	  redis2file [OPTIONS] key

	Available options:
	  -h, --help         Displays options
	  -v, --version      Shows file2redis' version.
	  -f, --filename     The path of the file to write to. (Defaults: generated temp file)
	  -e, --encoding     The encoding to use. (Defaults: utf8)
	  -p, --prefix       The filename prefix to use. (Defaults: redisfs)
	  -s, --suffix       The filename suffix to use.
	  -d, --deleteKey    Indicator to delete the key after the op. (Defaults: false)

    $  redis2file -e base64 -f test/test.pdf redisfs:A8D367BD-1CE7-4FB3-9F90-2E94AF25430C
	>> file -> test/test.pdf

## Using redisfs programmatically.
### Configuration & Construction
redisfs supports the follow configuration options that can be passed into either
the RedisFs constructor or the redisfs factory method.
	# options - Optional Hash of options.
	#   redis      - Existing instance of node_client.
	#   host       - String Redis host.  (Default: Redis' default)
	#   port       - Integer Redis port.  (Default: Redis' default)
	#   namespace  - String namespace prefix for generated Redis keys.
	#                (Default: redisfs).
	#   database   - Optional Integer of the Redis database to select.
	#   *dir       - Optional path to write files out to for generated files.
	#                (Default: your systems temporary directory)
	#   prefix     - Optional prefix to use for generated files.  (Default: 'redisfs')
	#   suffix     - Optional suffix to use for generated files. 
	#   deleteKey  - Optional boolean to indicate if the key should be
	#                deleted on a redis2file operation.  (Default: true)
	#   deleteFile - Optional boolean to indicate if the file should be
	#                deleted on a file2redis operation.  (Default: true)
	#
	# Note: all params marked as * represent future implementations
	#
	
	examples
	
	// defaults
    var redisfs = require('redisfs').redisfs();	

    // full customization
    var redis = require('redisfs').redisfs({
	  redis: clientInstance,
	  namespace: 'my:namespace',
	  prefix: 'my-prefix-',
	  suffix: '.pdf',
	  deleteKey: false,
	  deleteFile: false
	});

### file2redis 

	# Pumps a file's contents into a redis key and deletes the file. 
	#   filename     - The full path to the file to consume
	#   options      - Optional hash of options. 
	#     key        - Optional redis key.  If omitted a key will be 
	#                  generated using the default namespace and a uuid.
	#     encoding   - Optional file encoding.
	#     deleteFile - Optional boolean to indicate whether the file file
	#                  should be deleted after it is pumped into redis.
	#   callback     - Recieves either an error as the first param
	#                  or success hash that contains the key and reply
	#                  as the second param.
	file2redis: (filename, options..., callback) ->

    examples

    // defaults
	redisfs.file2redis('/path/to/file, function(err, result) {
	  if (err) throw err;
	  console.log("Generated redis key: " + result.key);	
	  console.log("Redis output: " + result.reply);	
	});
	
	// specify a key and override the encoding and deletion defaults
	var options = {key: 'my:key', encoding: 'base64', deleteFile: false};
	redisfs.file2redis('/path/to/file', options, function(err, result) {
	  if (err) throw err;
	  console.log("my redis key: " + result.key);	
	  console.log("Redis output: " + result.reply);	
	});
	
### redis2file
	#
	# Pumps a redis value to a file and deletes the redis key.
	#   key         - The redis key to fetch.
	#   options     - Optional hash of options.
	#     filename  - Optional filename to write to. assumes the file is
	#                 preexisting and writable.  If ommitted a temp file 
	#                 will be generated.
	#     encoding  - Optional file encoding, defaults to utf8
	#                 This overrides the instance level options if specified.
	#     *dir      - Optional path to write files out to for generated files.
	#                 This overrides the instance level options if specified.
	#     prefix    - Optional prefix to use for generated files.
	#                 This overrides the instance level options if specified.
	#     suffix    - Optional suffix to use for generated files. 
	#                 This overrides the instance level options if specified.
	#     deleteKey - Optional boolean to indicate if the key should be
	#                 removed after the get operation.  (Default: to value
	#                 set on instance)
	#   callback    - Receives the and error as the first param
	#                 or a success hash that contains the filename. 
	#                 *the path and a fd to the file.
	#
	# Note: all params marked as * represent future implementations
	#
	redis2file: (key, options..., callback) ->

    examples

    // defaults
	redisfs.redis2file('my:key', function(err, result) {
	  if (err) throw err;
	  console.log("output file: " + result);	
	});

    // customization
    var options = {
	  filename: 'myfile', 
	  encoding: 'base64', 
	  deleteKey: false
	};
	redisfs.redis2file('my:key', options, function(err, result) {
	  if (err) throw err;
	  console.log("output file: " + result);	
	});

    // customization
    var options = {
	  prefix: 'my-file-prefix-', 
	  suffix: '.txt'
	};
	redisfs.redis2file('my:key', options, function(err, result) {
	  if (err) throw err;
	  console.log("output file: " + result);	
	});

### cleanup
	#
	# Delete generated resources.
	#   options - Optional object indicating which generated resources to 
	#             delete (keys and/or files). Omission of options will result
	#             in the deletion of both files and keys.
	#     keys  - Optional boolean indicating whether files should be
	#             deleted.
	#     files - Optional boolean indicating whether generated files 
	#             should be deleted.
	#
    cleanup: (options) ->

    examples

    // defaults
    redisfs.cleanup();

    // delete keys but not files
    redisfs.cleanup({files: false});
    
### end
	#
	# End the redis connection and deletes all the resources generated during
	# the session.  Accepts the same args as cleanup.  To disable the cleanup
	# pass false. 
	#
	end: (options) ->
	
	examples
	
	redisfs.end();
	redisfs.end(false);
	redisfs.end({keys: true, files: false});
    
## License 

MIT License

Copyright (c) 2011 Sean McDaniel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

#### Author: [Sean McDaniel](http://www.mcdconsultingllc.com)
#### Contributors: