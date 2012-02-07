/*
# jQuery Extension
*/
var GifVJ;

$.fn.extend({
  __show: $.fn.show,
  __hide: $.fn.hide
});

$.fn.extend({
  show: function() {
    return this.addClass('show').removeClass('hide');
  },
  hide: function() {
    return this.addClass('hide').removeClass('show');
  }
});

$.fn.extend({
  isInput: function() {
    return this.is('input, textarea, select');
  },
  enableElement: function() {
    this.attr('disabled', null);
    return this.unbind('click.railsDisable');
  },
  disableElement: function() {
    this.attr('disabled', 'disabled');
    return this.bind('click.railsDisable', function(e) {
      return $.rails.stopEverything(e);
    });
  },
  bindAjaxHandler: function(handlers) {
    var eventName, handler;
    for (eventName in handlers) {
      handler = handlers[eventName];
      this.live('ajax:' + eventName, handler);
    }
    return this;
  }
});

$.extend($.Event.prototype, {
  hasModifierKey: function() {
    return this.altKey || this.ctlrKey || this.metaKey || this.shiftKey;
  }
  /*
  # GifVJ Class
  */
});

GifVJ = (function() {

  function GifVJ(canvas, urls, handler) {
    this.canvas = canvas;
    this.context = this.canvas.getContext('2d');
    this.urls = urls;
    this.handler = handler || {};
    this.parsers = [];
    this.datas = [];
    this.errors = [];
    this.parserHandler = {
      onParseProgress: $.proxy(this.onParseProgress, this),
      onParseComplete: $.proxy(this.onParseComplete, this),
      onParseError: $.proxy(this.onParseError, this)
    };
    this.load();
  }

  GifVJ.prototype.load = function() {
    var self, url, _i, _len, _ref, _results;
    self = this;
    _ref = this.urls;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      url = _ref[_i];
      _results.push($.ajax({
        url: url,
        beforeSend: function(req) {
          return req.overrideMimeType('text/plain; charset=x-user-defined');
        },
        complete: function(req) {
          var data, parser;
          data = req.responseText;
          parser = new GifVJ.Parser(data, null, self.parserHandler);
          return self.parsers.push(parser);
        }
      }));
    }
    return _results;
  };

  GifVJ.prototype.initPlayerIfCompleted = function() {
    if (this.datas.length + this.errors.length !== this.parsers.length) return;
    this.slot = 0;
    this.number = 0;
    this.player = new GifVJ.Player(this.canvas, this.datas[this.slot + this.number]);
    return this.handler.onComplete && this.handler.onComplete(this);
  };

  GifVJ.prototype.onParseProgress = function(parser) {
    var frame;
    if (!(parser.frames.length > 0)) return;
    frame = parser.frames[parser.frames.length - 1];
    this.canvas.width = parser.header.width;
    this.canvas.height = parser.header.height;
    return this.context.putImageData(frame, 0, 0);
  };

  GifVJ.prototype.onParseComplete = function(parser) {
    var percent;
    this.datas.push({
      frames: parser.frames,
      width: parser.header.width,
      height: parser.header.height
    });
    percent = Math.round(this.datas.length / this.parsers.length * 100);
    this.handler.onProgress && this.handler.onProgress(this, percent);
    return this.initPlayerIfCompleted();
  };

  GifVJ.prototype.onParseError = function(parser, error) {
    this.errors.push(error);
    this.handler.onError && this.handler.onError(this, error);
    return this.initPlayerIfCompleted();
  };

  GifVJ.prototype.onKeyDown = function(e) {
    var data, diffTime, index, keycode;
    if (!this.player) return;
    if ($(e.target).isInput()) return;
    if (e.hasModifierKey()) return;
    e.preventDefault();
    switch (e.which) {
      case 13:
        return this.player.toggle();
      case 39:
      case 74:
        return this.player.nextFrame();
      case 37:
      case 75:
        return this.player.prevFrame();
      case 82:
        return this.player.setReverse(!this.player.reverse);
      case 32:
        if (this.beforeTapTime) {
          diffTime = new Date - this.beforeTapTime;
          if (diffTime <= 2000) this.player.setDelay(diffTime / 8);
        }
        return this.beforeTapTime = new Date;
      case 49:
      case 50:
      case 51:
      case 52:
      case 53:
      case 54:
      case 55:
      case 56:
      case 57:
      case 89:
      case 85:
      case 73:
      case 79:
      case 80:
        keycode = e.which;
        if (keycode >= 49 && keycode <= 57) {
          this.number = keycode - 49;
        } else {
          switch (keycode) {
            case 89:
              this.slot = 9 * 0;
              break;
            case 85:
              this.slot = 9 * 1;
              break;
            case 73:
              this.slot = 9 * 2;
              break;
            case 79:
              this.slot = 9 * 3;
              break;
            case 80:
              this.slot = 9 * 4;
          }
        }
        index = this.slot + this.number;
        while (index >= 0) {
          data = this.datas[index];
          if (data) {
            this.player.setData(data);
            return;
          }
          index = index - this.datas.length;
        }
    }
  };

  GifVJ.prototype.start = function() {
    if (!this.player) return;
    return this.player.play();
  };

  return GifVJ;

})();

GifVJ.Parser = (function() {

  function Parser(data, canvas, handler) {
    this.stream = new Stream(data);
    this.canvas = canvas || document.createElement('canvas');
    this.handler = handler || {};
    this.frames = [];
    this.parse();
  }

  Parser.prototype.parse = function() {
    try {
      return parseGIF(this.stream, {
        hdr: $.proxy(this.onParseHeader, this),
        gce: $.proxy(this.onParseGraphicControlExtension, this),
        img: $.proxy(this.onParseImage, this),
        eof: $.proxy(this.onEndOfFile, this)
      });
    } catch (error) {
      if (this.handler.onParseError) {
        return this.handler.onParseError(this, error);
      } else {
        throw error;
      }
    }
  };

  Parser.prototype.pushFrame = function() {
    if (this.context) {
      this.frames.push(this.context.getImageData(0, 0, this.header.width, this.header.height));
      return this.context = null;
    }
  };

  Parser.prototype.onParseHeader = function(header) {
    this.header = header;
    this.canvas.width = this.header.width;
    return this.canvas.height = this.header.height;
  };

  Parser.prototype.onParseGraphicControlExtension = function(gce) {
    this.pushFrame();
    this.transparency = gce.transparencyGiven ? gce.transparencyIndex : null;
    return this.disposal_method = gce.disposalMethod;
  };

  Parser.prototype.onParseImage = function(image) {
    var color_table, data, index, pixel, _len, _ref;
    if (!this.context) this.context = this.canvas.getContext('2d');
    color_table = image.lctFlag ? image.lct : this.header.gct;
    data = this.context.getImageData(image.leftPos, image.topPos, image.width, image.height);
    _ref = image.pixels;
    for (index = 0, _len = _ref.length; index < _len; index++) {
      pixel = _ref[index];
      if (this.transparency !== pixel) {
        data.data[index * 4 + 0] = color_table[pixel][0];
        data.data[index * 4 + 1] = color_table[pixel][1];
        data.data[index * 4 + 2] = color_table[pixel][2];
        data.data[index * 4 + 3] = 255;
      } else if (this.disposal_method === 2 || this.disposal_method === 3) {
        data.data[index * 4 + 3] = 0;
      }
    }
    this.context.putImageData(data, image.leftPos, image.topPos);
    return this.handler.onParseProgress && this.handler.onParseProgress(this);
  };

  Parser.prototype.onEndOfFile = function() {
    this.pushFrame();
    return this.handler.onParseComplete && this.handler.onParseComplete(this);
  };

  return Parser;

})();

GifVJ.Player = (function() {

  function Player(canvas, data) {
    this.canvas = canvas;
    this.context = canvas.getContext('2d');
    this.setData(data);
    this.playing = false;
    this.reverse = false;
    this.delay = 100;
  }

  Player.prototype.setData = function(data) {
    this.data = data;
    this.frames = this.data.frames;
    this.index = 0;
    this.setFrame();
    this.canvas.width = this.data.width;
    return this.canvas.height = this.data.height;
  };

  Player.prototype.setFrame = function() {
    var frame;
    frame = this.frames[this.index];
    if (!frame) return;
    return this.context.putImageData(frame, 0, 0);
  };

  Player.prototype.stepFrame = function() {
    if (!this.playing) return;
    this.setFrame();
    if (this.reverse) {
      this.index -= 1;
      if (this.index < 0) this.index = this.frames.length - 1;
    } else {
      this.index += 1;
      if (this.index >= this.frames.length) this.index = 0;
    }
    return setTimeout($.proxy(this.stepFrame, this), this.delay);
  };

  Player.prototype.play = function() {
    this.playing = true;
    return this.stepFrame();
  };

  Player.prototype.stop = function() {
    return this.playing = false;
  };

  Player.prototype.toggle = function() {
    if (this.playing) {
      return this.stop();
    } else {
      return this.play();
    }
  };

  Player.prototype.nextFrame = function() {
    if (this.playing) return;
    this.index += 1;
    if (this.index >= this.frames.length) this.index = 0;
    return this.setFrame();
  };

  Player.prototype.prevFrame = function() {
    if (this.playing) return;
    this.index -= 1;
    if (this.index < 0) this.index = this.frames.length - 1;
    return this.setFrame();
  };

  Player.prototype.setReverse = function(reverse) {
    return this.reverse = reverse;
  };

  Player.prototype.setDelay = function(delay) {
    return this.delay = delay;
  };

  return Player;

})();

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
            return $('#content').fadeOut();
          }, 0);
          canvas.removeClass('prepared');
          $(document).keydown($.proxy(gifVj.onKeyDown, gifVj));
          return gifVj.start();
        }
      });
    }, 0);
  };
  return $('#form-gifs').bindAjaxHandler({
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
  });
});
