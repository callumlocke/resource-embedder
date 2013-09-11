ResourceEmbedder = require '../src/resource-embedder'
path = require 'path'
fs = require 'fs'

inputFilePath = path.resolve(path.join(__dirname, 'fixtures/input.html'))
outputFilePath = path.resolve(path.join(__dirname, 'fixtures/expected.html'))
correctOutput = fs.readFileSync(outputFilePath).toString()

exports['resource-embedder'] = (test) ->
  test.expect 1

  embedder = new ResourceEmbedder
    htmlFile: inputFilePath

  embedder.get (result) ->
    test.equal result, correctOutput, 'result should match output.html.'
    fs.writeFileSync path.join(__dirname, '../test-output.html'), result
    test.done()
