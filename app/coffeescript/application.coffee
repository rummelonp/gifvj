###
# jQuery Extension
###

# Saved default show & hide
$.fn.extend
  __show: $.fn.show
  __hide: $.fn.hide

# Replace show & hide to bootstrap
$.fn.extend
  show: ->
    this.addClass('show').removeClass('hide')
  hide: ->
    this.addClass('hide').removeClass('show')

# Add methods to fn
$.fn.extend
  isInput: ->
    this.is 'input, textarea, select'
  enableElement: ->
    this.attr 'disabled', null
    this.unbind 'click.railsDisable'
  disableElement: ->
    this.attr 'disabled', 'disabled'
    this.bind 'click.railsDisable', (e) ->
      $.rails.stopEverything(e)
  bindAjaxHandler: (handlers) ->
    for eventName, handler of handlers
      this.live 'ajax:' + eventName, handler
    this

# Add methods to Event
$.extend $.Event.prototype, hasModifierKey: ->
  return this.altKey || this.ctlrKey || this.metaKey || this.shiftKey

###
# GifVJ Class
###
class GifVJ
  constructor: (canvas, urls, handler) ->
    @canvas = canvas
    @context = @canvas.getContext '2d'
    @urls = urls
    @handler = handler || {}
    @parsers = []
    @datas = []
    @errors = []
    @parserHandler =
      onParseProgress: $.proxy(@onParseProgress, this)
      onParseComplete: $.proxy(@onParseComplete, this)
      onParseError: $.proxy(@onParseError, this)
    @load()

  load: ->
    self = this
    for url in @urls
      $.ajax
        url: url
        beforeSend: (req) ->
          req.overrideMimeType 'text/plain; charset=x-user-defined'
        complete: (req) ->
          data = req.responseText
          parser = new GifVJ.Parser data, null, self.parserHandler
          self.parsers.push parser

  initPlayerIfCompleted: ->
    return unless @datas.length + @errors.length == @parsers.length
    @slot = 0
    @number = 0
    @player = new GifVJ.Player(@canvas, @datas[@slot + @number])
    @handler.onComplete && @handler.onComplete this

  onParseProgress: (parser) ->
    return unless parser.frames.length > 0
    frame = parser.frames[parser.frames.length - 1]
    @canvas.width = parser.header.width
    @canvas.height = parser.header.height
    @context.putImageData(frame, 0, 0)

  onParseComplete: (parser) ->
    @datas.push
      frames: parser.frames
      width: parser.header.width
      height: parser.header.height
    percent = Math.round(@datas.length / @parsers.length * 100)
    @handler.onProgress && @handler.onProgress this, percent
    @initPlayerIfCompleted()

  onParseError: (parser, error) ->
    @errors.push error
    @handler.onError && @handler.onError this, error
    @initPlayerIfCompleted()

  onKeyDown: (e) ->
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
        @player.setReverse !@player.reverse
      when 32 # Space
        if @beforeTapTime
          diffTime = new Date - @beforeTapTime
          if diffTime <= 2000
            @player.setDelay diffTime / 8
        @beforeTapTime = new Date
      when 49, 50, 51, 52, 53, 54, 55, 56, 57, 89, 85, 73, 79, 80 # 1-9, y, u, i, o, p
        keycode = e.which
        if keycode >= 49 && keycode <= 57
          @number = keycode - 49
        else
          switch keycode
            when 89 then @slot = 9 * 0
            when 85 then @slot = 9 * 1
            when 73 then @slot = 9 * 2
            when 79 then @slot = 9 * 3
            when 80 then @slot = 9 * 4
        index = @slot + @number
        while index >= 0
          data = @datas[index]
          if data
            @player.setData data
            return
          index = index - @datas.length

  start: ->
    return unless @player
    @player.play()

class GifVJ.Parser
  constructor: (data, canvas, handler) ->
    @stream = new Stream(data)
    @canvas = canvas || document.createElement 'canvas'
    @handler = handler || {}
    @frames = []
    @parse()

  parse: ->
    try
      parseGIF @stream,
        hdr: $.proxy(@onParseHeader, this)
        gce: $.proxy(@onParseGraphicControlExtension, this)
        img: $.proxy(@onParseImage, this)
        eof: $.proxy(@onEndOfFile, this)
    catch error
      if @handler.onParseError
        @handler.onParseError this, error
      else
        throw error

  pushFrame: ->
    if @context
      @frames.push @context.getImageData(0, 0, @header.width, @header.height)
      @context = null

  onParseHeader: (header) ->
    @header = header
    @canvas.width = @header.width
    @canvas.height = @header.height

  onParseGraphicControlExtension: (gce) ->
    @pushFrame()
    @transparency = if gce.transparencyGiven then gce.transparencyIndex else null
    @disposal_method = gce.disposalMethod

  onParseImage: (image) ->
    unless @context
      @context = @canvas.getContext '2d'
    color_table = if image.lctFlag then image.lct else @header.gct
    data = @context.getImageData(image.leftPos, image.topPos, image.width, image.height)
    for pixel, index in image.pixels
      if @transparency != pixel
        data.data[index * 4 + 0] = color_table[pixel][0]
        data.data[index * 4 + 1] = color_table[pixel][1]
        data.data[index * 4 + 2] = color_table[pixel][2]
        data.data[index * 4 + 3] = 255
      else if @disposal_method == 2 || @disposal_method == 3
        data.data[index * 4 + 3] = 0
    @context.putImageData(data, image.leftPos, image.topPos)
    @handler.onParseProgress && @handler.onParseProgress this

  onEndOfFile: ->
    @pushFrame()
    @handler.onParseComplete && @handler.onParseComplete this

class GifVJ.Player
  constructor: (canvas, data)->
    @canvas = canvas
    @context = canvas.getContext('2d')
    @setData data
    @playing = false
    @reverse = false
    @delay = 100

  setData: (data) ->
    @data = data
    @frames = @data.frames
    @index = 0
    @setFrame()
    @canvas.width = @data.width
    @canvas.height = @data.height

  setFrame: ->
    frame = @frames[@index]
    return unless frame
    @context.putImageData(frame, 0, 0)

  stepFrame: ->
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
    setTimeout $.proxy(@stepFrame, this), @delay

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

  setReverse: (reverse) ->
    @reverse = reverse

  setDelay: (delay) ->
    @delay = delay

$ ->
  startGifVJ = (data) ->
    $w = $(window)
    container = $('#canvas')
    form = $('#form-gifs')
    progress = $('.progress')
    bar = progress.find('.bar')
    canvas = $('canvas').addClass('prepared')

    resizeContainer = ->
      container.width $w.width()
      container.height $w.height()

    form.fadeOut ->
      progress.fadeIn()

    resizeContainer()
    $w.resize resizeContainer

    setTimeout ->
      new GifVJ canvas.get(0), data,
        onProgress: (gifVj, percent) ->
          bar.width(percent + '%')
        onComplete: (gifVj) ->
          setTimeout ->
            $('#content').fadeOut()
          , 0
          canvas.removeClass('prepared')
          $(document).keydown $.proxy(gifVj.onKeyDown, gifVj)
          gifVj.start()
    , 0

  $('#form-gifs').bindAjaxHandler
    beforeSend: ->
      $(this).find('input').disableElement()
    success: (req, data) ->
      startGifVJ(data)
    error: (e, req) ->
      alert = $('#error-alert')
        .text(req.responseText)
        .fadeIn()
      setTimeout ->
        alert.fadeOut()
      , 3000
    complete: ->
      $(this).find('input').enableElement()
