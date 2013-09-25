ResourceEmbedder = require '../src/resource-embedder'
path = require 'path'
fs = require 'fs'

inputFilePath = path.resolve(path.join(__dirname, 'fixtures/input.html'))
outputFilePath = path.resolve(path.join(__dirname, 'fixtures/expected.html'))
correctOutput = fs.readFileSync(outputFilePath).toString()

exports['resource-embedder'] = (test) ->
  test.expect 2

  embedder = new ResourceEmbedder
    htmlFile: inputFilePath

  embedder.get (result, warnings) ->
    fs.writeFileSync path.join(__dirname, '../test-output.html'), result
    test.ok result is correctOutput, 'resulting markup should match output.html.'
    test.strictEqual warnings.length, 2
    test.done()
