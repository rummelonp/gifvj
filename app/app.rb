require 'open-uri'

class GifVJ < Padrino::Application
  register LessInitializer
  register Padrino::Rendering
  register Padrino::Helpers

  set :cache, Padrino::Cache::Store::Memory.new

  get :index do
    erb :index
  end

  post :gifs do
    begin
      @gifs = gifs(params[:name])
      @urls = download(@gifs)

      require 'json'
      content_type :json
      @urls.to_json
    rescue
      logger.error $!
      halt 400
    end
  end

  def gifs(name)
    blog_hostname, gifs, posts = "#{name}.tumblr.com", [], []
    loop do
      logger.info "gifs: #{blog_hostname}, #{posts.size}"
      data = Tumblife.client.posts(blog_hostname, type: :photo, offset: posts.size)
      posts += data.posts
      gifs += posts.map {|p|
        p.photos.first.original_size.url
      }.select {|u|
        u.match(/\.gif$/)
      }.uniq
      break if gifs.size >= 45 || posts.size >= 200
    end
    gifs
  end

  def download(gifs)
    urls, threads, mutex = [], [], Mutex.new
    gifs.each do |gif|
      name = File.basename(gif)
      path = File.join settings.public_folder, 'images', name
      url  = "/images/#{name}"
      if File.exists? path
        urls << url
        next
      end
      logger.info "download: download #{gif}"
      threads << Thread.new do
        begin
          data = open(gif, 'rb').read
          open(path, 'wb').print data
          mutex.synchronize do
            urls << url
            logger.info "download: complete #{gif}"
            logger.flush
          end
        rescue
          mutex.synchronize do
            logger.error $!
            logger.flush
          end
        end
      end
    end
    threads.each {|t| t.join}
    urls
  end
end
