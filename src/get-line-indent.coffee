###
  Returns the characters leading from the last newline to `index`, if those characters are whitespace, otherwise returns an empty string.
###

module.exports = (index, str) ->
  indent = []
  while index >= 0
    character = str[--index]
    switch character
      when ' ', '\t'
        indent.unshift character
      when '\n'
        return indent.join ''
      else
        return ''
  indent.join ''
