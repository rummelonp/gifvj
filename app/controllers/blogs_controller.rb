class BlogsController < ApplicationController
  def index
    @names = Blog.recent_names
  end

  def image_paths
    @image_paths = Blog.find(params[:name]).image_paths
    render json: @image_paths
  rescue
    render text: $!.message, status: 400
  end
end
