$(function() {
  var startGifVJ;
  startGifVJ = function(data) {
    var $w, bar, canvas, container, form, progress, resizeContainer;
    $w = $(window);
    container = $('#canvas');
    form = $('#form-gifs');
    progress = $('.progress');
    bar = progress.find('.bar');
    canvas = $('canvas').addClass('prepared');
    resizeContainer = function() {
      container.width($w.width());
      return container.height($w.height());
    };
    form.fadeOut(function() {
      return progress.fadeIn();
    });
    resizeContainer();
    $w.resize(resizeContainer);
    return setTimeout(function() {
      return new GifVJ(canvas.get(0), data, {
        onProgress: function(gifVj, percent) {
          return bar.width(percent + '%');
        },
        onComplete: function(gifVj) {
          setTimeout(function() {
            $('nav').fadeOut();
            return $('#content').fadeOut();
          }, 0);
          canvas.removeClass('prepared');
          $(document).keydown($.proxy(gifVj.onKeyDown, gifVj));
          return gifVj.start();
        }
      });
    }, 0);
  };
  $('#form-gifs').bindAjaxHandler({
    beforeSend: function() {
      return $(this).find('input').disableElement();
    },
    success: function(req, data) {
      return startGifVJ(data);
    },
    error: function(e, req) {
      var alert;
      alert = $('#error-alert').text(req.responseText).fadeIn();
      return setTimeout(function() {
        return alert.fadeOut();
      }, 3000);
    },
    complete: function() {
      return $(this).find('input').enableElement();
    }
  }).find('input[type="text"]').keyup(function() {
    var submit, text;
    text = $(this);
    if (text.attr('disabled') === 'disabled') {
      return;
    }
    submit = text.nextAll('input[type="submit"]');
    if (text.val().length > 0) {
      return submit.enableElement();
    } else {
      return submit.disableElement();
    }
  });
  return $(document).keypress(function(e) {
    if ($(e.target).isInput()) {
      return;
    }
    if (e.which === 63 && e.shiftKey) {
      return $('#about').modal('toggle');
    }
  });
});
