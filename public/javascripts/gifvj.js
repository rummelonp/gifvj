/*
# GifVJ Class
*/

var GifVJ,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

GifVJ = (function() {
  function GifVJ(canvas, urls, handler) {
    var beforeSend, complete, url, _i, _len, _ref,
      _this = this;
    this.canvas = canvas;
    this.urls = urls != null ? urls : [];
    this.handler = handler != null ? handler : [];
    this.onKeyDown = __bind(this.onKeyDown, this);
    this.onResize = __bind(this.onResize, this);
    this.onParseError = __bind(this.onParseError, this);
    this.onParseComplete = __bind(this.onParseComplete, this);
    this.onParseProgress = __bind(this.onParseProgress, this);
    this.context = this.canvas.getContext('2d');
    this.parsers = [];
    this.data = [];
    this.errors = [];
    beforeSend = function(req) {
      return req.overrideMimeType('text/plain; charset=x-user-defined');
    };
    complete = function(req) {
      return _this.parsers.push(new GifVJ.Parser(_this, req.responseText));
    };
    _ref = this.urls;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      url = _ref[_i];
      $.ajax({
        url: url,
        beforeSend: beforeSend,
        complete: complete
      });
    }
  }

  GifVJ.prototype.onParseProgress = function(parser) {
    var frame;
    if (!(parser.frames.length > 0)) {
      return;
    }
    frame = parser.frames[parser.frames.length - 1];
    this.canvas.width = parser.header.width;
    this.canvas.height = parser.header.height;
    this.context.putImageData(frame, 0, 0);
    return this.resizeCanvas();
  };

  GifVJ.prototype.onParseComplete = function(parser) {
    var percent;
    this.data.push({
      frames: parser.frames,
      width: parser.header.width,
      height: parser.header.height
    });
    percent = Math.round(this.data.length / this.urls.length * 100);
    if (this.handler.onProgress) {
      this.handler.onProgress(this, percent);
    }
    if (this.isCompleted()) {
      return this.initPlayer();
    }
  };

  GifVJ.prototype.onParseError = function(parser, error) {
    this.errors.push(error);
    if (this.handler.onError) {
      this.handler.onError(this, error);
    }
    if (this.isCompleted()) {
      return this.initPlayer();
    }
  };

  GifVJ.prototype.isCompleted = function() {
    return this.data.length + this.errors.length === this.parsers.length;
  };

  GifVJ.prototype.initPlayer = function() {
    if (!this.isCompleted()) {
      return;
    }
    this.slots = [
      {
        offset: 0,
        index: 0
      }, {
        offset: 9,
        index: 0
      }, {
        offset: 18,
        index: 0
      }, {
        offset: 27,
        index: 0
      }, {
        offset: 36,
        index: 0
      }
    ];
    this.slot = this.slots[0];
    this.player = new GifVJ.Player(this, this.canvas, this.data[this.slot.offset + this.slot.index]);
    if (this.handler.onComplete) {
      return this.handler.onComplete(this);
    }
  };

  GifVJ.prototype.onResize = function(e) {
    return this.resizeCanvas();
  };

  GifVJ.prototype.resizeCanvas = function() {
    var $canvas, $window, canvasRealHeight, canvasRealWidth, heightRatio, ratio, widthRatio, windowHeight, windowWidth;
    $window = $(window);
    $canvas = $(this.canvas);
    windowWidth = $window.width();
    windowHeight = $window.height();
    canvasRealWidth = $canvas.attr('width');
    canvasRealHeight = $canvas.attr('height');
    widthRatio = windowWidth / canvasRealWidth;
    heightRatio = windowHeight / canvasRealHeight;
    if (widthRatio < heightRatio) {
      ratio = heightRatio;
      $canvas.css({
        left: "-" + ((canvasRealWidth * ratio - windowWidth) / 2) + "px",
        top: '0px'
      });
    } else {
      ratio = widthRatio;
      $canvas.css({
        left: '0px',
        top: "-" + ((canvasRealHeight * ratio - windowHeight) / 2) + "px"
      });
    }
    return $canvas.css({
      width: canvasRealWidth * ratio,
      height: canvasRealHeight * ratio
    });
  };

  GifVJ.prototype.onKeyDown = function(e) {
    var datum, diffTime, index, keycode;
    if (!this.player) {
      return;
    }
    if ($(e.target).isInput()) {
      return;
    }
    if (e.hasModifierKey()) {
      return;
    }
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
        return this.player.toggleReverse();
      case 32:
        if (this.beforeTime) {
          diffTime = new Date - this.beforeTime;
          if (diffTime <= 2000) {
            this.player.setDelay(diffTime / 8);
          }
        }
        return this.beforeTime = new Date;
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
        if ((49 <= keycode && keycode <= 57)) {
          this.slot.index = keycode - 49;
        } else {
          switch (keycode) {
            case 89:
              this.slot = this.slots[0];
              break;
            case 85:
              this.slot = this.slots[1];
              break;
            case 73:
              this.slot = this.slots[2];
              break;
            case 79:
              this.slot = this.slots[3];
              break;
            case 80:
              this.slot = this.slots[4];
          }
        }
        index = this.slot.offset + this.slot.index;
        while (index >= 0) {
          if (datum = this.data[index]) {
            this.player.setData(datum);
            return;
          }
          index = index - this.data.length;
        }
    }
  };

  GifVJ.prototype.start = function() {
    if (!this.player) {
      return;
    }
    return this.player.play();
  };

  return GifVJ;

})();

GifVJ.Parser = (function() {
  function Parser(gifVj, data) {
    var error;
    this.gifVj = gifVj;
    this.onEndOfFile = __bind(this.onEndOfFile, this);
    this.onParseImage = __bind(this.onParseImage, this);
    this.onParseGraphicControlExtension = __bind(this.onParseGraphicControlExtension, this);
    this.onParseHeader = __bind(this.onParseHeader, this);
    this.canvas = document.createElement('canvas');
    this.frames = [];
    try {
      parseGIF(new Stream(data), {
        hdr: this.onParseHeader,
        gce: this.onParseGraphicControlExtension,
        img: this.onParseImage,
        eof: this.onEndOfFile
      });
    } catch (_error) {
      error = _error;
      this.gifVj.onParseError(this, error);
    }
  }

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
    return this.disposalMethod = gce.disposalMethod;
  };

  Parser.prototype.onParseImage = function(image) {
    var colorTable, imageData, index, pixel, _i, _len, _ref;
    if (!this.context) {
      this.context = this.canvas.getContext('2d');
    }
    colorTable = image.lctFlag ? image.lct : this.header.gct;
    imageData = this.context.getImageData(image.leftPos, image.topPos, image.width, image.height);
    _ref = image.pixels;
    for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
      pixel = _ref[index];
      if (this.transparency !== pixel) {
        imageData.data[index * 4 + 0] = colorTable[pixel][0];
        imageData.data[index * 4 + 1] = colorTable[pixel][1];
        imageData.data[index * 4 + 2] = colorTable[pixel][2];
        imageData.data[index * 4 + 3] = 255;
      } else if (this.disposalMethod === 2 || this.disposalMethod === 3) {
        imageData.data[index * 4 + 3] = 0;
      }
    }
    this.context.putImageData(imageData, image.leftPos, image.topPos);
    return this.gifVj.onParseProgress(this);
  };

  Parser.prototype.onEndOfFile = function() {
    this.pushFrame();
    if (this.frames.length > 1) {
      return this.gifVj.onParseComplete(this);
    } else {
      return this.gifVj.onParseError(this, new Error('Not a animation GIF file.'));
    }
  };

  return Parser;

})();

GifVJ.Player = (function() {
  function Player(gifVj, canvas, datum) {
    this.gifVj = gifVj;
    this.canvas = canvas;
    this.stepFrame = __bind(this.stepFrame, this);
    this.context = canvas.getContext('2d');
    this.setData(datum);
    this.playing = false;
    this.reverse = false;
    this.delay = 100;
  }

  Player.prototype.setData = function(data) {
    this.data = data;
    this.frames = this.data.frames;
    this.index = 0;
    this.canvas.width = this.data.width;
    this.canvas.height = this.data.height;
    this.gifVj.resizeCanvas();
    return this.setFrame();
  };

  Player.prototype.setFrame = function() {
    var frame;
    frame = this.frames[this.index];
    if (!frame) {
      return;
    }
    return this.context.putImageData(frame, 0, 0);
  };

  Player.prototype.stepFrame = function() {
    if (!this.playing) {
      return;
    }
    this.setFrame();
    if (this.reverse) {
      this.index -= 1;
      if (this.index < 0) {
        this.index = this.frames.length - 1;
      }
    } else {
      this.index += 1;
      if (this.index >= this.frames.length) {
        this.index = 0;
      }
    }
    return setTimeout(this.stepFrame, this.delay);
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
    if (this.playing) {
      return;
    }
    this.index += 1;
    if (this.index >= this.frames.length) {
      this.index = 0;
    }
    return this.setFrame();
  };

  Player.prototype.prevFrame = function() {
    if (this.playing) {
      return;
    }
    this.index -= 1;
    if (this.index < 0) {
      this.index = this.frames.length - 1;
    }
    return this.setFrame();
  };

  Player.prototype.toggleReverse = function() {
    return this.setReverse(!this.reverse);
  };

  Player.prototype.setReverse = function(reverse) {
    this.reverse = reverse;
  };

  Player.prototype.setDelay = function(delay) {
    this.delay = delay;
  };

  return Player;

})();
