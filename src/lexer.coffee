{count, last} = require './helpers'

exports.Lexer = class Lexer
  constructor: ->
    # @tokens = [
    #   ['ID', 'foo', [0,0]]
    #   [':', ':', [0,0]]
    #   ['VALUE', 'bar', [0,0]]
    #   ['EOF', '<<EOF>>', [0,0]]
    # ]
  tokenize: (code, opts={}) ->
    @tokens = []

    @chunkLine =
      opts.line or 0
    @chunkColumn = opts.column or 0
    code = @clean code

    i = 0
    while @chunk = code[i..]
      consumed = \
            @identifierToken() or
            @valueToken() or
            @whitespaceToken() or
            @newlineToken()
      [@chunkLine, @chunkColumn] = @getLineAndColumnFromChunk consumed
      i += consumed

    console.log @tokens

  setInput: ->
    @pos = 0

  identifierToken: ->
    return 0 unless match = IDENTIFIER.exec @chunk
    identifier = match[0]
    @token 'ID', match[1], 0, identifier.length

    identifier.length

  valueToken: ->
    return 0 unless match = VALUE.exec @chunk
    value = match[0]
    @token 'VALUE', value, 0, value.length

    value.length

  whitespaceToken: ->
    return 0 unless (match = WHITESPACE.exec @chunk) or
                    (nline = @chunk.charAt(0) is '\n')
    prev = last @tokens
    prev[if match then 'spaced' else 'newLine'] = true if prev
    if match then match[0].length else 0

  newlineToken: (offset) ->
    return 0 unless @chunk.lastIndexOf '\n' >= 0
    @token 'TERMINATOR', '\n', offset, 0 unless @tag() is 'TERMINATOR'
    1

  tag: ->
    (last @tokens)[0]

  makeToken: (tag, value, offsetInChunk = 0, length = value.length) ->
    locationData = {}
    [locationData.first_line, locationData.first_column] =
      @getLineAndColumnFromChunk offsetInChunk

    # Use length - 1 for the final offset - we're supplying the last_line and the last_column,
    # so if last_column == first_column, then we're looking at a character of length 1.
    lastCharacter = Math.max 0, length - 1
    [locationData.last_line, locationData.last_column] =
      @getLineAndColumnFromChunk offsetInChunk + lastCharacter

    token = [tag, value, locationData]

    token

  # Add a token to the results.
  # `offset` is the offset into the current @chunk where the token starts.
  # `length` is the length of the token in the @chunk, after the offset.  If
  # not specified, the length of `value` will be used.
  #
  # Returns the new token.
  token: (tag, value, offsetInChunk, length) ->
    token = @makeToken tag, value, offsetInChunk, length
    @tokens.push token
    token

  lex: ->
    token = @tokens[@pos++]
    if token
      [tag, @yytext, @yylloc] = token
      @yylineno = 0
    else
      tag = ''

    tag

  clean: (code) ->
    code = code.slice(1) if code.charCodeAt(0) is BOM
    code = code.replace(/\r/g, '').replace TRAILING_SPACES, ''
    if WHITESPACE.test code
        code = "\n#{code}"
        @chunkLine--
    code

  getLineAndColumnFromChunk: (offset) ->
    if offset is 0
      return [@chunkLine, @chunkColumn]

    if offset >= @chunk.length
      string = @chunk
    else
      string = @chunk[..offset-1]

    lineCount = count string, '\n'

    column = @chunkColumn
    if lineCount > 0
      lines = string.split '\n'
      column = last(lines).length
    else
      column += string.length

    [@chunkLine + lineCount, column]

WHITESPACE = /^[^\n\S]+/
BOM = 65279

IDENTIFIER = /^(\w+):/

VALUE = /^[a-zA-Z0-9_$]+/

TRAILING_SPACES = /\s+$/
