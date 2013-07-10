###
# GifVJ Class
###
class GifVJ
  constructor: (@canvas, @urls = [], @handler = []) ->
    @context = @canvas.getContext '2d'
    @parsers = []
    @data = []
    @errors = []
    beforeSend = (req) =>
      req.overrideMimeType 'text/plain; charset=x-user-defined'
    complete = (req) =>
      @parsers.push new GifVJ.Parser @, req.responseText
    for url in @urls
      $.ajax
        url: url
        beforeSend: beforeSend
        complete: complete

  onParseProgress: (parser) =>
    return unless parser.frames.length > 0
    frame = parser.frames[parser.frames.length - 1]
    @canvas.width = parser.header.width
    @canvas.height = parser.header.height
    @context.putImageData frame, 0, 0

  onParseComplete: (parser) =>
    @data.push
      frames: parser.frames
      width: parser.header.width
      height: parser.header.height
    percent = Math.round @data.length / @urls.length * 100
    if @handler.onProgress
      @handler.onProgress this, percent
    if @isCompleted()
      @initPlayer()

  onParseError: (parser, error) =>
    @errors.push error
    if @handler.onError
      @handler.onError this, error
    if @isCompleted()
      @initPlayer()

  isCompleted: ->
    @data.length + @errors.length == @parsers.length

  initPlayer: ->
    return unless @isCompleted()
    @slots = [
      {offset: 0,  index: 0}
      {offset: 9,  index: 0}
      {offset: 18, index: 0}
      {offset: 27, index: 0}
      {offset: 36, index: 0}
    ]
    @slot = @slots[0]
    @player = new GifVJ.Player @, @canvas, @data[@slot.offset + @slot.index]
    if @handler.onComplete
      @handler.onComplete this

  onKeyDown: (e) =>
    return unless @player
    return if $(e.target).isInput()
    return if e.hasModifierKey()
    e.preventDefault()
    switch e.which
      when 13 # Enter
        @player.toggle()
      when 39, 74 # j / →
        @player.nextFrame()
      when 37, 75 # k / ←
        @player.prevFrame()
      when 82 # r
        @player.toggleReverse()
      when 32 # Space
        if @beforeTime
          diffTime = new Date - @beforeTime
          if diffTime <= 2000
            @player.setDelay diffTime / 8
        @beforeTime = new Date
      when 49, 50, 51, 52, 53, 54, 55, 56, 57, 89, 85, 73, 79, 80 # 1-9, y, u, i, o, p
        keycode = e.which
        if 49 <= keycode <= 57
          @slot.index = keycode - 49
        else
          switch keycode
            when 89 then @slot = @slots[0]
            when 85 then @slot = @slots[1]
            when 73 then @slot = @slots[2]
            when 79 then @slot = @slots[3]
            when 80 then @slot = @slots[4]
        index = @slot.offset + @slot.index
        while index >= 0
          if datum = @data[index]
            @player.setData datum
            return
          index = index - @data.length

  start: ->
    return unless @player
    @player.play()

class GifVJ.Parser
  constructor: (@gifVj, data) ->
    @canvas = document.createElement 'canvas'
    @frames = []
    try
      parseGIF new Stream(data),
        hdr: @onParseHeader
        gce: @onParseGraphicControlExtension
        img: @onParseImage
        eof: @onEndOfFile
    catch error
      @gifVj.onParseError this, error

  pushFrame: ->
    if @context
      @frames.push @context.getImageData 0, 0, @header.width, @header.height
      @context = null

  onParseHeader: (header) =>
    @header = header
    @canvas.width = @header.width
    @canvas.height = @header.height

  onParseGraphicControlExtension: (gce) =>
    @pushFrame()
    @transparency = if gce.transparencyGiven then gce.transparencyIndex else null
    @disposalMethod = gce.disposalMethod

  onParseImage: (image) =>
    unless @context
      @context = @canvas.getContext '2d'
    colorTable = if image.lctFlag then image.lct else @header.gct
    imageData = @context.getImageData image.leftPos, image.topPos, image.width, image.height
    for pixel, index in image.pixels
      if @transparency != pixel
        imageData.data[index * 4 + 0] = colorTable[pixel][0]
        imageData.data[index * 4 + 1] = colorTable[pixel][1]
        imageData.data[index * 4 + 2] = colorTable[pixel][2]
        imageData.data[index * 4 + 3] = 255
      else if @disposalMethod == 2 || @disposalMethod == 3
        imageData.data[index * 4 + 3] = 0
    @context.putImageData imageData, image.leftPos, image.topPos
    @gifVj.onParseProgress this

  onEndOfFile: =>
    @pushFrame()
    if @frames.length > 1
      @gifVj.onParseComplete this
    else
      @gifVj.onParseError this, new Error 'Not a animation GIF file.'

class GifVJ.Player
  constructor: (@gifVj, @canvas, datum)->
    @context = canvas.getContext '2d'
    @setData datum
    @playing = false
    @reverse = false
    @delay = 100

  setData: (@data) ->
    @frames = @data.frames
    @index = 0
    @canvas.width = @data.width
    @canvas.height = @data.height
    @setFrame()

  setFrame: ->
    frame = @frames[@index]
    return unless frame
    @context.putImageData frame, 0, 0

  stepFrame: =>
    return unless @playing
    @setFrame()
    if @reverse
      @index -= 1
      if @index < 0
        @index = @frames.length - 1
    else
      @index += 1
      if @index >= @frames.length
        @index = 0
    setTimeout @stepFrame, @delay

  play: ->
    @playing = true
    @stepFrame()

  stop: ->
    @playing = false

  toggle: ->
    if @playing
      @stop()
    else
      @play()

  nextFrame: ->
    return if @playing
    @index += 1
    if @index >= @frames.length
      @index = 0
    @setFrame()

  prevFrame: ->
    return if @playing
    @index -= 1
    if @index < 0
      @index = @frames.length - 1
    @setFrame()

  toggleReverse: ->
    @setReverse !@reverse

  setReverse: (@reverse) ->

  setDelay: (@delay) ->
