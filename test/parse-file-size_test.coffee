parseFileSize = require '../src/parse-file-size'

exports['parse-file-size'] = (test) ->
  test.expect 9

  test.equal parseFileSize('5KB'), 5120
  test.equal parseFileSize('25kb'), 25600
  test.equal parseFileSize('10 kb'), 10240
  test.equal parseFileSize('1.46484KB'), 1500
  test.equal parseFileSize('256b'), 256
  test.equal parseFileSize('256 bytes'), 256
  test.equal parseFileSize('256'), 256

  test.throws -> parseFileSize('2000 purple')
  test.throws -> parseFileSize('um 5kb')

  test.done()
