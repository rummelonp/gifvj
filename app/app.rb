class GifVJ < Padrino::Application
  register LessInitializer
  register Padrino::Rendering
  register Padrino::Helpers

  set :cache, Padrino::Cache::Store::Memory.new

  get :index do
    erb :index
  end
end
