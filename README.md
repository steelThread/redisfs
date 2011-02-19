	 ____          _ _     _____    
	|  _ \ ___  __| (_)___|  ___|__ 
	| |_) / _ \/ _` | / __| |_ / __|
	|  _ <  __/ (_| | \__ \  _|\__ \
	|_| \_\___|\__,_|_|___/_|  |___/


Simple utility for pumping files in and out of Redis.

## About
RedisFs is a dead simple utility for moving files in and out of Redis.  

## Installing
	$ npm install redisfs
 
## Usage
### Configuration & Construction
RedisFs supports the follow configuration options that can be passed into either
the RedisFs constructor or the redisfs factory method.
	redis      - Existing instance of node_redis.
	host       - String Redis host.  (Default: Redis' default)
	port       - Integer Redis port.  (Default: Redis' default)
	namespace  - String namespace prefix for generated Redis keys. (Default: redisfs).
	database   - Optional Integer of the Redis database to select.
	*dir       - Optional path to write files out to for generated files.
	             (Default: your systems temporary directory)
	prefix     - Optional prefix to use for generated files.  (Default: 'redisfs')
	suffix     - Optional suffix to use for generated files. 
	deleteKey  - Optional boolean to indicate if the key should be
	             deleted on a redis2file operation.  (Default: true)
	deleteFile - Optional boolean to indicate if the file should be
	             deleted on a file2redis operation.  (Default: true)
	
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
	#   options       
	#     key        - Optional redis key.  If omitted a key will be 
	#                  generated using the default namespace and a uuid.
	#     encoding   - Optional file encoding.
	#     deleteFile - Optional boolean to indicate whether the file file
	#                  should be deleted after it is pumped into redis.
	#   callback     - Recieves either an error as the first param
	#                  or success hash that contains the key and reply
	#                  as the second param.
	file2redis: (filename, options, callback) ->

    examples

    // defaults
	redisfs.file2redis('/path/to/file, function(err, result) {
	  if (err) throw err;
	  console.log("Generated redis key: " + result.key);	
	  console.log("Redis output: " + result.reply);	
	});
	
	// specify a key and override the encoding and deletion defaults
	var options = {key: 'my:key', encoding: 'base64', deleteFile: false};
	redisfs.file2redis('/path/to/file, options, function(err, result) {
	  if (err) throw err;
	  console.log("my redis key: " + result.key);	
	  console.log("Redis output: " + result.reply);	
	});
	

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