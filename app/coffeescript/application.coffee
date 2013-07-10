$window = $(window)
$document = $(document)

$document.ready ->
  $container = $ '#canvas'
  $canvas = $ 'canvas'
  $form = $ '#form-gifs'
  $progress = $ '.progress'
  $bar = $progress.find '.bar'

  resizeContainer = ->
    $container.width $window.width()
    $container.height $window.height()

  gifVjHandler =
    onProgress: (gifVj, percent) ->
      $bar.width percent + '%'
    onComplete: (gifVj) ->
      $('nav, #content').fadeOut()
      $canvas.removeClass 'prepared'
      gifVj.start()

  startGifVJ = (data) ->
    $container.show()
    $canvas.addClass 'prepared'
    $form.fadeOut ->
      $progress.fadeIn()
    resizeContainer()
    $window.resize resizeContainer
    gifVj = new GifVJ $canvas.get(0), data, gifVjHandler
    $window.resize gifVj.onResize
    $document.keydown gifVj.onKeyDown

  $form.bindAjaxHandler
    beforeSend: ->
      $form.find('input').disableElement()
    success: (req, data) ->
      startGifVJ(data)
    error: (e, req) ->
      $alert = $('#error-alert')
        .text(req.responseText)
        .fadeIn()
      setTimeout ->
        $alert.fadeOut()
      , 3000
    complete: ->
      $form.find('input').enableElement()

  $form.find('input[type="text"]').keyup ->
    $text = $(this)
    return if $text.attr('disabled') == 'disabled'
    $submit = $text.nextAll('input[type="submit"]')
    if $text.val().length > 0
      $submit.enableElement()
    else
      $submit.disableElement()

  $document.keypress (e) ->
    return if $(e.target).isInput()
    if e.which == 63 && e.shiftKey # ?
      $('#about').modal('toggle')
