fs = require 'fs'
Resource = require '../src/resource'

posOptions =
  scripts: true
  stylesheets: true
  threshold: Infinity

potentiallyEmbeddable = Resource::potentiallyEmbeddable
getThreshold = Resource::getThreshold
convertCSSResources = Resource::convertCSSResources

module.exports =
  'Resource':

    '#potentiallyEmbeddable':
      'must be a script or link tag': (t) ->
        t.strictEqual false, potentiallyEmbeddable(
          'b', {}, posOptions
        )
        t.done()
      'link tag':
        'true if [rel=stylesheet]': (t) ->
          t.strictEqual true, potentiallyEmbeddable(
            'link', {rel: 'stylesheet', href:'file.css'}, posOptions
          )
          t.done()
        'false if [rel!=stylesheet]': (t) ->
          t.strictEqual false, potentiallyEmbeddable(
            'link', {rel: 'something', href:'file.css'}, posOptions
          )
          t.strictEqual false, potentiallyEmbeddable(
            'link', {rel: undefined, href:'file.css'}, posOptions
          )
          t.done()
        'requires media attr to be missing/blank or "all"': (t) ->
          t.strictEqual false, potentiallyEmbeddable(
            'link', {rel: 'stylesheet', href:'file.css', media: 'print'}, posOptions
          )
          t.strictEqual true, potentiallyEmbeddable(
            'link', {rel: 'stylesheet', href:'file.css', media: 'all', href:'file.css'}, posOptions
          )
          t.strictEqual true, potentiallyEmbeddable(
            'link', {rel: 'stylesheet', href:'file.css', media: ''}, posOptions
          )
          t.strictEqual true, potentiallyEmbeddable(
            'link', {rel: 'stylesheet', href:'file.css'}, posOptions
          )
          t.done()
        'false if options.stylesheets not true': (t) ->
          t.strictEqual false, potentiallyEmbeddable(
            'link', {rel: 'stylesheet', href:'file.css'}, {scripts: true}
          )
          t.done()
      'script tag':
        'handles type attribute correctly': (t) ->
          t.strictEqual false, potentiallyEmbeddable(
            'script', {type: 'text/x-template', src: 'file.js'}, posOptions
          )
          t.strictEqual true, potentiallyEmbeddable(
            'script', {type: 'application/javascript', src: 'file.js'}, posOptions
          )
          t.strictEqual true, potentiallyEmbeddable(
            'script', {type: 'text/javascript', src: 'file.js'}, posOptions
          )
          t.strictEqual true, potentiallyEmbeddable(
            'script', {src: 'file.js'}, posOptions
          )
          t.strictEqual true, potentiallyEmbeddable(
            'script', {type: '', src: 'file.js'}, posOptions
          )
          t.done()
        'false if options.scripts not true': (t) ->
          t.strictEqual false, potentiallyEmbeddable(
            'script', {src: 'file.js'}, {stylesheets: true}
          )
          t.done()
        'false if missing src attribute': (t) ->
          t.strictEqual false, potentiallyEmbeddable(
            'script', {}, posOptions
          )
          t.done()
        'false if src is an absolute URL': (t) ->
          t.strictEqual false, potentiallyEmbeddable(
            'script', {src: 'http://yo.com/foo.js'}, posOptions
          )
          t.strictEqual false, potentiallyEmbeddable(
            'script', {src: 'https://yo.com/foo.js'}, posOptions
          )
          t.strictEqual false, potentiallyEmbeddable(
            'script', {src: '//yo.com/foo.js'}, posOptions
          )
          t.done()

    '#getThreshold':
      '0 if "false" or "0"': (t) ->
        t.expect 2
        t.strictEqual 0, getThreshold('0')
        t.strictEqual 0, getThreshold('false')
        t.done()
      'converts through parseFileSize correctly': (t) ->
        t.strictEqual 1024, getThreshold('1kb')
        t.done()
      'uses value from options if no data-embed value supplied': (t) ->
        t.expect 2
        t.strictEqual 2048, getThreshold(undefined, {threshold: '2kb'})
        t.strictEqual 2048, getThreshold(null, {threshold: '2kb'})
        t.done()
      'Infinity when data-embed is an empty string (ie attribute with no value specified)': (t) ->
        t.strictEqual Infinity, getThreshold('', {})
        t.done()
      'data-embed attr takes precedence over options': (t) ->
        t.strictEqual 2048, getThreshold('2kb', {threshold: '1kb'})
        t.strictEqual Infinity, getThreshold('', {threshold: '10kb'})
        t.done()

    '#convertCSSResources':
      'converts relative resources correctly': (t) ->
        result = convertCSSResources(
          fs.readFileSync(__dirname + '/fixtures/styles/urls.css'),
          'styles'
        )
        t.strictEqual result, """
        .some-class {
          filter: progid:DXImageTransform.Microsoft.AlphaImageLoader(
            src='styles/images/test.jpg',
            sizingMethod='scale'
          );
          background-image: url('images/foo.png');
        }
        .another-class {
          background-image: url(styles/more-images/bar.jpg?12345);
        }

        """
        t.done()

    '#stripQuotes':
      'works': (t) ->
        t.strictEqual Resource::stripQuotes('"foo"'), 'foo'
        t.strictEqual Resource::stripQuotes("'foo'"), 'foo'
        t.done()
      'ok with non quoted strings': (t) ->
        t.strictEqual Resource::stripQuotes('bar'), 'bar'
        t.done()

    '#convertPath':
      'works': (t) ->
        conversions =
          'images/bar.jpg?12345': 'styles/images/bar.jpg?12345'
          '../images/bar.jpg?12345': 'images/bar.jpg?12345'
        for from, to of conversions
          t.strictEqual Resource::convertPath(from, 'styles'), to
        t.done()
