class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from StandardError, with: :render_server_error

  def not_found
    render status: 404, template: 'errors/not_found.html.erb'
  end

  def render_server_error(e)
    logger.error e
    @message = e.message
    render status: 500, template: 'errors/server_error.html.erb'
  end
end
