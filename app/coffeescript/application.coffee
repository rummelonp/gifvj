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
            $('nav').fadeOut()
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
  .find('input[type="text"]').keyup ->
    text = $(this)
    return if text.attr('disabled') == 'disabled'
    submit = text.nextAll('input[type="submit"]')
    if text.val().length > 0
      submit.enableElement()
    else
      submit.disableElement()

  $(document).keypress (e) ->
    return if $(e.target).isInput()
    if e.which == 63 && e.shiftKey # ?
      $('#about').modal('toggle')
