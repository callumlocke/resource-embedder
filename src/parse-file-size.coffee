multipliers =
  kb: 1024
  KB: 1024
  b: 1
  bytes: 1

module.exports = (str) ->

  number = str.match(/^[0-9\.]+/)
  if !number? or !number.length
    throw new Error "Number not found in string: #{str}"

  unit = str.substring(number.length).trim()

  if unit.length is 0
    return +number

  if not multipliers[unit]? or (+number != +(+number).toString())
    throw new Error "Not understood: '#{str}'"

  Math.round(multipliers[unit] * number)
