exports.count = (string, substr) ->
  num = pos = 0
  return 1/0 unless substr.length
  num++ while pos = 1 + string.indexOf substr, pos
  num

exports.last = last = (array, back) -> array[array.length - (back or 0) - 1]
