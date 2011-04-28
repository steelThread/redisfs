test: deps
	@vows -spec

generate-js: deps
	@find src -name '*.coffee' | xargs coffee -c -o lib

deps:
	@test `which coffee` || echo 'You need to have CoffeeScript in your PATH.\nPlease install it using `brew install coffee-script` or `npm install coffee-script`.'

link: generate-js
	@test `which npm` || echo 'You need npm to do npm link... makes sense?'
	@npm link
	@rm -fr lib/

publish: generate-js
	@test `which npm` || echo 'You need npm to do npm publish... makes sense?'
	@npm publish
	@rm -fr lib/

dev: generate-js
	@coffee -wc --no-wrap -o lib src/*.coffee

.PHONY: all