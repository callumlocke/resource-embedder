fs = require 'graceful-fs'
path = require 'path'
htmlparser = require 'htmlparser2'
_ = require 'lodash'

defaultOptions =
  threshold: '5KB'
  stylesheets: true
  scripts: true

getLineIndent = require './get-line-indent'
parseFileSize = require './parse-file-size'

indentEachLine = (str, indent) ->
  lines = str.split '\n'
  indent + lines.join "\n#{indent}"

shouldBeEmbedded = (path, dataEmbed, options) ->
  switch dataEmbed
    when 'false', '0'
      return false
    when ''
      return true
    when null, undefined
      maxFileSize = options.threshold
    else
      maxFileSize = parseFileSize dataEmbed
  fs.statSync(path).size < maxFileSize


module.exports = class ResourceEmbedder
  constructor: (_options) ->
    # Normalise arguments
    if typeof _options is 'string'
      htmlFile = arguments[0]
      _options = arguments[1]
      _options.htmlFile = htmlFile
    
    # Build options
    @options = _.extend {}, defaultOptions, _options
    if not @options.assetRoot
      @options.assetRoot = path.dirname(@options.htmlFile) unless @options.assetRoot?
    if typeof @options.threshold isnt 'number'
      @options.threshold = parseFileSize @options.threshold

  get: (callback) ->
    fs.readFile @options.htmlFile, (err, inputMarkup) =>
      throw err if err

      inputMarkup = inputMarkup.toString()

      # Build array of resources as scripts and links are encountered during parse
      resources = []
      nextResource = null
      parser = new htmlparser.Parser
        onopentag: (tagName, attributes) =>
          switch tagName
            when 'script'
              if @options.scripts && attributes.src?
                scriptPath = path.join(@options.assetRoot, attributes.src)
                if shouldBeEmbedded scriptPath, attributes['data-embed'], @options
                  nextResource =
                    type: 'script'
                    elementStartIndex: parser.startIndex
                    path: scriptPath
                    body: fs.readFileSync(scriptPath).toString().trim()
            when 'link'
              if @options.stylesheets && attributes.rel == 'stylesheet' && attributes.href?
                linkPath = path.join(@options.assetRoot, attributes.href)
                if shouldBeEmbedded linkPath, attributes['data-embed'], @options
                  nextResource =
                    type: 'style'
                    elementStartIndex: parser.startIndex
                    path: linkPath
                    body: fs.readFileSync(linkPath).toString().trim()

        onclosetag: (tagName) ->
          if nextResource?
            nextResource.elementEndIndex = parser.endIndex
            resources.push nextResource
            nextResource = null

      parser.write(inputMarkup)
      parser.end()

      # Build output markup string
      outputMarkup = ''

      index = 0
      for resource in resources
        multiline = (resource.body.indexOf('\n') isnt -1)
        if multiline
          indent = getLineIndent resource.elementStartIndex, inputMarkup
        else indent = ''

        body = (if indent.length then indentEachLine(resource.body, indent) else resource.body)

        outputMarkup += (
          inputMarkup.substring(index, resource.elementStartIndex) +
          "<#{resource.type}>" +
          (if multiline then '\n' else '') +
          body +
          (if multiline then '\n' else '') +
          indent + "</#{resource.type}>"
        )
        index = resource.elementEndIndex + 1
      outputMarkup += inputMarkup.substring index

      callback outputMarkup
