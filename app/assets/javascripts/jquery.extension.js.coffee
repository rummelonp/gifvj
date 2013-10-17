$.fn.extend
  __show: $.fn.show
  __hide: $.fn.hide

$.fn.extend
  show: ->
    this.addClass('show').removeClass('hide')
  hide: ->
    this.addClass('hide').removeClass('show')

$.fn.extend
  isInput: ->
    this.is 'input, textarea, select'
  enableElement: ->
    this.prop 'disabled', false
    this.unbind 'click.railsDisable'
  disableElement: ->
    this.prop 'disabled', true
    this.bind 'click.railsDisable', (e) ->
      $.rails.stopEverything(e)
  bindAjaxHandler: (handlers) ->
    for eventName, handler of handlers
      this.on 'ajax:' + eventName, handler
    this

$.extend $.Event.prototype, hasModifierKey: ->
  return this.altKey || this.ctlrKey || this.metaKey || this.shiftKey
