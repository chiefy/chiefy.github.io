
.PHONY: clean

node_modules:
	@npm install

build: node_modules
	@mkdir -p $@
	@npm run build

clean:
	@rm -rf build

push: build
	@cp -R build /tmp
	@$(MAKE) clean
	@git checkout gh-pages
	@cp -R /tmp/build/* .
