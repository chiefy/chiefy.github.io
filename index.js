var Metalsmith = require('metalsmith');
var ms = new Metalsmith(__dirname);
var fs = require('fs');

/*eslint-disable*/
var _layouts     = require('metalsmith-layouts');
var _collections = require('metalsmith-collections');
var _assets      = require('metalsmith-assets');
var _sass        = require('metalsmith-sass');
var _permalinks  = require('metalsmith-permalinks');
var _slug        = require('metalsmith-slug');
var _define      = require('metalsmith-define');
var _gist        = require('metalsmith-gist');
var excerpts     = require('metalsmith-excerpts')();
var beautify     = require('metalsmith-beautify')();
var uglify       = require('metalsmith-uglify')();
var markdown     = require('metalsmith-markdown')();
var drafts       = require('metalsmith-drafts')();
/*eslint-enable*/

var pkg = JSON.parse(fs.readFileSync('package.json'));
var define = _define({
	pkg: pkg,
	env: process.env.NODE_ENV,
	baseurl: (process.env.NODE_ENV === 'dev')	?
		'http://localhost:8080' : pkg.baseurl
});
var layouts = _layouts({engine: 'swig'});
var collections = _collections({
	posts: {
		pattern: 'posts/*.md',
		sortBy: 'date',
		reverse: true
	}
});
var assets = _assets({destination: './assets'});
var sass = _sass({outputDir: './assets'});
var slug = _slug({
	patterns: [
		'posts/*.md'
	]
});
var permalinks = _permalinks({
	pattern: ':title',
	relative: false
});
var gist = _gist({
	debug: true,
	caching: false,
	cacheDir: '.gists'
});

ms
	.use(define)
	.use(drafts)
	.use(collections)
	.use(sass)
	.use(assets)
	.use(slug)
	.use(markdown)
	.use(gist)
	.use(permalinks)
	.use(excerpts)
	.use(layouts)
	.use(beautify)
	.use(uglify)
	.build(function onBuild(err, files) {
		if (err) {
			throw err;
		}
	});
