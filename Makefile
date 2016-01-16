
.PHONY: clean

node_modules:
	@npm install

build: node_modules
	@mkdir -p $@
	@npm run build

clean:
	@rm -rf build

push: clean build
	@git checkout master
	@cp -R /build/* . && rm -rf build
