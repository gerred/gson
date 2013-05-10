{count, last} = require './helpers'

exports.Lexer = class Lexer
  tokenize: (code, opts={}) ->
    @indent   = 0              # The current indentation level.
    @indebt   = 0              # The over-indentation at the current level.
    @outdebt  = 0              # The under-outdentation at the current level.
    @indents  = []             # The stack of all current indentation levels.
    @ends     = []             # The stack for pairing up tokens.
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
            @lineToken()
      [@chunkLine, @chunkColumn] = @getLineAndColumnFromChunk consumed
      i += consumed

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

  lineToken: ->
    return 0 unless match = MULTI_DENT.exec @chunk
    indent = match[0]
    @seenFor = no
    size = indent.length - 1 - indent.lastIndexOf '\n'
    noNewlines = @unfinished()
    if size - @indebt is @indent
      if noNewlines then @suppressNewlines() else @newlineToken 0
      return indent.length

    if size > @indent
      if noNewlines
        @indebt = size - @indent
        @suppressNewlines()
        return indent.length
      diff = size - @indent + @outdebt
      @token 'INDENT', diff, indent.length - size, size
      @indents.push diff
      @ends.push 'OUTDENT'
      @outdebt = @indebt = 0
    else
      @indebt = 0
      @outdentToken @indent - size, noNewlines, indent.length
    @indent = size
    indent.length

  newlineToken: (offset) ->
    return 0 unless @chunk.lastIndexOf '\n' >= 0
    @token 'TERMINATOR', '\n', offset, 0 unless @tag() is 'TERMINATOR'
    this

  outdentToken: (moveOut, noNewlines, outdentLength) ->
    while moveOut > 0
      len = @indents.length - 1
      if @indents[len] is undefined
        moveOut = 0
      else if @indents[len] is @outdebt
        moveOut -= @outdebt
        @outdebt = 0
      else if @indents[len] < @outdebt
        @outdebt -= @indents[len]
        moveOut  -= @indents[len]
      else
        dent = @indents.pop() + @outdebt
        moveOut -= dent
        @outdebt = 0
        @pair 'OUTDENT'
        @token 'OUTDENT', dent, 0, outdentLength
    @outdebt -= moveOut if dent
    @tokens.pop() while @value() is ';'

    @token 'TERMINATOR', '\n', outdentLength, 0 unless @tag() is 'TERMINATOR' or noNewlines
    this

  suppressNewlines: ->
    @tokens.pop() if @value() is '\\'
    this

  unfinished: ->
    LINE_CONTINUER.test(@chunk) or
    @tag() in ['\\', '.', '?.', '?::', 'UNARY', 'MATH', '+', '-', 'SHIFT', 'RELATION'
               'COMPARE', 'LOGIC', 'THROW', 'EXTENDS']

  pair: (tag) ->
    unless tag is wanted = last @ends
      @error "unmatched #{tag}" unless 'OUTDENT' is wanted
      # Auto-close INDENT to support syntax like this:
      #
      #     el.click((event) ->
      #       el.hide())
      #
      @indent -= size = last @indents
      @outdentToken size, true
      return @pair tag
    @ends.pop()


  tag: (index, tag) ->
    (tok = last @tokens, index) and if tag then tok[0] = tag else tok[0]

  # Peek at a value in the current token stream.
  value: (index, val) ->
    (tok = last @tokens, index) and if val then tok[1] = val else tok[1]


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

MULTI_DENT = /^(?:\n[^\n\S]*)+/

LINE_CONTINUER  = /// ^ \s* (?: , | \??\.(?![.\d]) | :: ) ///
