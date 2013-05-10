{parser} = require './node_json'
{Lexer} = require './lexer'
fs = require 'fs'
_ = require 'lodash'
{debug} = require 'util'

class Compiler
  compile: ->


    fs.readFile "./test.json", {encoding: 'utf-8'}, (err, data) =>
      rootObject = {}
      parser.lexer = new Lexer
      parser.yy = _
      parser.lexer.tokenize(data)

      results = parser.parse data
      console.log results

compiler = new Compiler()
compiler.compile()