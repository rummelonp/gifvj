# -*- coding: utf-8 -*-

require 'open-uri'

class GifVJ < Padrino::Application
  register Padrino::Rendering
  register Padrino::Helpers

  set :cache, Redis::Store.new(namespace: 'gifvj')

  get :index do
    erb :index
  end

  post :gifs do
    begin
      @name = params[:name]
      unless @name.to_s.match(/^[\w\d-]+$/)
        raise "Bad Blog Name"
      end

      @gifs = GifVJ.cache.get @name
      unless @gifs
        @gifs = gifs @name
        GifVJ.cache.set @name, @gifs, expires_in: 1.hour
      end
      @urls = download @gifs
      if @urls.size == 0
        raise "Gif Not Found"
      end

      content_type :json
      @urls.to_json
    rescue
      logger.error $!
      logger.flush
      halt 400, $!.message
    end
  end

  def gifs(name)
    blog_hostname, gifs, posts, offset = "#{name}.tumblr.com", [], [], 0
    loop do
      logger.info "gifs: #{blog_hostname}, #{posts.size}"
      logger.flush
      data = Tumblife.client.posts(blog_hostname, type: :photo, offset: offset)
      posts += data.posts
      gifs = posts.map {|p|
        p.photos.map{|i| i.original_size.url}
      }.flatten.select {|u|
        u.match(/\.gif$/)
      }.uniq
      break if gifs.size >= 45 ||
        posts.size >= 200 ||
        posts.size == offset
      offset = posts.size
    end
    gifs.slice(0, 45)
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
      logger.flush
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
