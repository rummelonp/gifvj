/*
# jQuery Extension
*/

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
});
