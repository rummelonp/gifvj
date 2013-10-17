GifVJ::Application.routes.draw do
  scope module: :blogs do
    get  '/'            => :index
    post '/image_paths' => :image_paths
  end

  match '*a' => 'application#not_found', via: [:get, :post, :put, :delete]
end
