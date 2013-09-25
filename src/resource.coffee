parseFileSize = require './parse-file-size'
fs = require 'fs'
path = require 'path'

# Awesome regex stolen from
# https://github.com/yeoman/grunt-usemin/blob/v2.0/lib/fileprocessor.js#L38
cssURLMatcher = /(src=|url\(\s*)['"]?([^'"\)#?]+)(?:[#?](?:[^'"\)]*))?['"]?\s*\)?/gm

module.exports = class Resource
  constructor: (@tagName, @attributes, @options) ->

  isEmbeddable: (callback) ->
    if @embed?
      callback @embed
    else
      if @potentiallyEmbeddable()
        threshold = @getThreshold()
        if !threshold
          callback @embed = false
        else
          @getContentsForEmbedding (notFound) =>
            if (notFound)
              @warning = "File does not exist: #{@fullFilePath}"
              callback @embed = false
            else
              callback @embed = (threshold > @getByteLength())
      else
        callback @embed = false

  potentiallyEmbeddable: (tagName=@tagName, attributes=@attributes, options=@options) ->
    # Aims to return false as quickly as possible if we can be sure it's NOT embeddable
    # based solely on tagName, attributes, or options (NB: we're not checking the
    # threshold yet). Otherwise returns true, meaning it *might* be embeddable (as far as
    # we can tell without looking at the file contents).
    switch tagName
      when 'script'
        @target = attributes.src
        return false if (
          !options.scripts ||
          !(
            switch attributes.type
              when null, undefined, '', 'application/javascript', 'text/javascript'
                true
              else false
          ) ||
          !Resource::isLocalPath(attributes.src)
        )
      when 'link'
        @target = attributes.href
        return false if (
          !options.stylesheets ||
          attributes.rel != 'stylesheet' ||
          !(
            switch attributes.media
              when null, undefined, '', 'all'
                true
              else false
          ) ||
          !Resource::isLocalPath(attributes.href)
        )
      else
        return false
    return true

  getThreshold: (embedAttr = @attributes?['data-embed'], options=@options) ->
    switch embedAttr
      when 'false', '0'
        0
      when null, undefined
        parseFileSize options.threshold
      when ''
        Infinity
      else
        parseFileSize embedAttr

  getContentsForEmbedding: (callback) ->
    # Returns the contents of the file, but trimmed, and run through convertCSSResources
    # (if CSS).
    relFilePath = (if @tagName is 'script' then @attributes.src else @attributes.href)
    @fullFilePath = path.resolve(path.join(@options.assetRoot, relFilePath))
    fs.exists @fullFilePath, (exists) =>
      if !exists
        callback(true) # true means error (file not found)
      else
        fs.readFile @fullFilePath, (err, @contents) =>
          throw err if err
          if @tagName is 'link'
            @cssDirName = path.dirname @attributes.href
            @contents = @convertCSSResources()
          @contents = @contents.toString().trim()
          callback()

  convertCSSResources: (css=@contents, cssDirName=@cssDirName) ->
    css = css.toString()
    matches = css.match cssURLMatcher
    if matches?
      replacements = {}
      for match in matches
        switch match.substring(0,3)
          when 'url'
            relPath = Resource::stripQuotes match.match(/^url\(([^\)]*)\)$/)[1]
          when 'src'
            relPath = Resource::stripQuotes match.match(/^src=(.*)$/)[1]
          else throw new Error 'Something wrong with the regex'
        if Resource::isLocalPath(relPath)
          convertedPath = Resource::convertPath(relPath, cssDirName)
          replacements[match] = match.replace(relPath, convertedPath)
      for own from, to of replacements
        css = css.replace from, to, 'g'
    return css

  getByteLength: (contents=@contents) ->
    if !contents?
      throw new Error 'UNDEFINED @contents for some reason!'
    if typeof contents is 'string'
      Buffer.byteLength(contents, 'utf8')
    else
      contents.length

  stripQuotes: (str) ->
    switch str[0]
      when "'", '"'
        str.substring 1, str.length-1
      else
        str

  isLocalPath: (path) ->
    (
      path && path.length &&
      (path.indexOf('//') == -1)
    )

  convertPath: (relPath, cssDirName) ->
    path.normalize(path.join(cssDirName, relPath))
