ResourceEmbedder = require '../src/resource-embedder'
path = require 'path'
fs = require 'fs'

inputFilePath = path.resolve(path.join(__dirname, 'fixtures/messy.html'))
outputFilePath = path.resolve(path.join(__dirname, 'fixtures/expected/messy.html'))
correctOutput = fs.readFileSync(outputFilePath).toString()

exports['resource-embedder'] = (test) ->
  test.expect 2

  embedder = new ResourceEmbedder
    htmlFile: inputFilePath

  embedder.get (result, warnings) ->
    fs.writeFileSync path.join(__dirname, '../test-dump.html'), result
    test.ok result is correctOutput, 'processed markup should be as expected.'
    test.strictEqual warnings.length, 2
    test.done()
