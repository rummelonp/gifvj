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
# GifJV Class
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

  playIfComplete: ->
    return unless @datas.length + @errors.length == @parsers.length
    @player = new GifVJ.Player(@canvas, @datas[0])
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
    @playIfComplete()

  onParseError: (parser, error) ->
    @errors.push error
    @handler.onError && @handler.onError this, error
    @playIfComplete()

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
    @index = 0
    @playing = false
    @reverse = false
    @delay = 100

  setData: (data) ->
    @data = data
    @frames = @data.frames
    @canvas.width = @data.width
    @canvas.heifht = @data.height

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
        @index = @frame.length - 1
    else
      @index += 1
      if @index >= @frames.length
        @index = 0
    setTimeout($.proxy(@stepFrame, this), @delay)

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
    @set()

  prevFrame: ->
    return if @playing
    @index -= 1
    if @index < 0
      @index = @frames.length - 1
    @set()

  setReverse: (reverse) ->
    @revecse = reverse

  setDelay: (delay) ->
    @delay = delay

do ->
  $('#form-gifs').bindAjaxHandler
    beforeSend: ->
      $(this).find('input').disableElement()
    success: (req, data) ->
      form = $('#form-gifs')
      progress = $('.progress')
      bar = progress.find('.bar')
      canvas = $('canvas').addClass('prepared')
      form.fadeOut ->
        progress.fadeIn ->
          new GifVJ canvas.get(0), data,
            onProgress: (gifVj, percent) ->
              bar.width(percent + '%')
            onComplete: (gifVj) ->
              canvas.removeClass('prepared')
              $('#content').fadeOut()
              gifVj.player.play()
    error: (e, req) ->
      alert = $('#error-alert')
        .text(req.responseText)
        .fadeIn()
      setTimeout ->
        alert.fadeOut()
      , 3000
    complete: ->
      $(this).find('input').enableElement()
