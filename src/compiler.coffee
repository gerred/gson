{parser} = require './node_json'
fs = require 'fs'
_ = require 'lodash'

class Compiler
  compile: ->


    fs.readFile "./test.json", {encoding: 'utf-8'}, (err, data) =>
      rootObject = {}

      _.extend(rootObject, @buildJSON(pair)) for pair in parser.parse data

      console.log rootObject

  buildJSON: (pair) ->
    obj = {}
    obj[pair[0]] = pair[1]
    obj


compiler = new Compiler()
compiler.compile()