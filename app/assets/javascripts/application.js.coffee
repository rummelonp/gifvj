#= require bootstrap
#= require jquery_ujs
#= require jquery.extension
#= require jquery.autocomplete
#= require gif
#= require gifvj

$window = $(window)
$document = $(document)

$document.ready ->
  do ->
    $('a[rel="external"]').prop 'target', '_blank'

  do ->
    $about = $ '.about'
    $document.keypress (e) ->
      return if $(e.target).isInput()
      if e.which == 63 && e.shiftKey # ?
        $about.modal('toggle')

  do ->
    $form = $ 'form'
    $name = $form.find '.name'
    $submit = $form.find '.submit'
    $alert = $ '.alert'
    alertTimer = null
    $form.bindAjaxHandler
      beforeSend: ->
        $name.disableElement()
        $submit.disableElement()
      success: (req, data) ->
        $container = $ '.canvas-container'
        $canvas = $container.find 'canvas'
        $progress = $ '.progress'
        $bar = $progress.find '.progress-bar'
        $container.show()
        $canvas.addClass 'prepared'
        $alert.fadeOut()
        $form.fadeOut ->
          $progress.fadeIn()
        resizeContainer = ->
          $container.width $window.width()
          $container.height $window.height()
        resizeContainer()
        $window.resize resizeContainer
        gifVj = new GifVJ $canvas.get(0), data,
          onProgress: (gifVj, percent) ->
            $bar.width percent + '%'
          onComplete: (gifVj) ->
            $('nav, .content').fadeOut()
            $canvas.removeClass 'prepared'
            gifVj.start()
        $window.resize gifVj.onResize
        $document.keydown gifVj.onKeyDown
      error: (e, req) ->
        $alert.text(req.responseText)
          .fadeIn()
        clearTimeout alertTimer
        alertTimer = setTimeout ->
          $alert.fadeOut()
        , 3000
      complete: ->
        $name.enableElement()
        $submit.enableElement()

    $name.keyup ->
      return if $name.prop 'disabled'
      if $name.val().length > 0
        $submit.enableElement()
      else
        $submit.disableElement()
