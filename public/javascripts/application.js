var $document, $window;

$window = $(window);

$document = $(document);

$document.ready(function() {
  var $bar, $canvas, $container, $form, $progress, gifVjHandler, resizeContainer, startGifVJ;
  $container = $('#canvas');
  $canvas = $('canvas');
  $form = $('#form-gifs');
  $progress = $('.progress');
  $bar = $progress.find('.bar');
  resizeContainer = function() {
    $container.width($window.width());
    return $container.height($window.height());
  };
  gifVjHandler = {
    onProgress: function(gifVj, percent) {
      return $bar.width(percent + '%');
    },
    onComplete: function(gifVj) {
      $('nav, #content').fadeOut();
      $canvas.removeClass('prepared');
      $document.keydown(gifVj.onKeyDown);
      return gifVj.start();
    }
  };
  startGifVJ = function(data) {
    $canvas.addClass('prepared');
    $form.fadeOut(function() {
      return $progress.fadeIn();
    });
    resizeContainer();
    $window.resize(resizeContainer);
    return new GifVJ($canvas.get(0), data, gifVjHandler);
  };
  $form.bindAjaxHandler({
    beforeSend: function() {
      return $form.find('input').disableElement();
    },
    success: function(req, data) {
      return startGifVJ(data);
    },
    error: function(e, req) {
      var $alert;
      $alert = $('#error-alert').text(req.responseText).fadeIn();
      return setTimeout(function() {
        return $alert.fadeOut();
      }, 3000);
    },
    complete: function() {
      return $form.find('input').enableElement();
    }
  });
  $form.find('input[type="text"]').keyup(function() {
    var $submit, $text;
    $text = $(this);
    if ($text.attr('disabled') === 'disabled') {
      return;
    }
    $submit = $text.nextAll('input[type="submit"]');
    if ($text.val().length > 0) {
      return $submit.enableElement();
    } else {
      return $submit.disableElement();
    }
  });
  return $document.keypress(function(e) {
    if ($(e.target).isInput()) {
      return;
    }
    if (e.which === 63 && e.shiftKey) {
      return $('#about').modal('toggle');
    }
  });
});
