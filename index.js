var Metalsmith = require('metalsmith');
var ms = new Metalsmith(__dirname);
var fs = require('fs');

/*eslint-disable*/
var markdown    = require('metalsmith-markdown');
var layouts     = require('metalsmith-layouts');
var collections = require('metalsmith-collections');
var assets      = require('metalsmith-assets');
var sass        = require('metalsmith-sass');
var permalinks  = require('metalsmith-permalinks');
var slug        = require('metalsmith-slug');
var define      = require('metalsmith-define');
var excerpts    = require('metalsmith-excerpts');
var beautify    = require('metalsmith-beautify');
/*eslint-enable*/

var pkg = JSON.parse(fs.readFileSync('package.json'));

ms
	.use(define({
		pkg: pkg,
		env: process.env.NODE_ENV,
		baseurl: process.env.NODE_ENV === 'dev' ? 'http://localhost:8080' : pkg.baseurl
	}))
	.use(collections({
		posts: {
			pattern: 'posts/*.md',
			sortBy: 'date',
			reverse: true
		}
	}))
	.use(sass({
		outputDir: './assets'
	}))
	.use(assets({
		destination: './assets'
	}))
	.use(slug({
		patterns: [
			'posts/*.md'
		]
	}))
	.use(markdown())
	.use(permalinks({
		pattern: ':title',
		relative: false
	}))
	.use(excerpts())
	.use(layouts({
		engine: 'swig'
	}))
	.use(beautify());


ms
	.build(function onBuild(err, files) {
		if (err) {
			throw err;
		}
	});
