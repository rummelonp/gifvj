require 'open-uri'

class Blog
  include Cacheable

  class Error < StandardError
  end

  class InvalidName < Error
  end

  class ImageNotFound < Error
  end

  RECENT_NAMES_KEY = "#{NAMESPACE}:blog:recent_names"

  MAX_IMAGE_SIZE = 45

  def self.recent_names
    cache.hgetall(RECENT_NAMES_KEY)
      .to_a
      .sort_by { |(_, v)| v.to_i }
      .reverse
      .take(10)
      .map(&:first)
  end

  def self.find(name)
    if name.blank? || !name.match(/^[\w\d\.-]+$/)
      raise InvalidName, 'Bad blog name'
    end
    new(name)
  end

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def image_paths
    urls = cache.get(name)
    unless urls
      urls = fetch_image_urls(name)
      cache.set(name, urls, expires_in: 1.hour)
    end
    images = urls.map { |url| Image.new(url) }
    Parallel.map(images, in_threads: 45) { |image| image.fetch }
    images.select!(&:exist?)
    if images.empty?
      raise ImageNotFound, 'Gif not found'
    end
    cache.hincrby(RECENT_NAMES_KEY, name.sub(/\.tumblr\.com\Z/, ''), 1)
    images.map(&:path)
  end

  private

  def fetch_image_urls(name)
    name = "#{name}.tumblr.com" unless name.include?('.')
    urls, posts, offset = [], [], 0
    loop do
      Rails.logger.info "fetch images: #{name}, #{posts.size}"
      data = Tumblife.posts(name, type: :photo, offset: offset)
      posts += data.posts
      urls = posts.map { |post|
        post.photos.map { |i| i.original_size.url }
      }.flatten.select { |url|
        url.match(/\.gif\Z/)
      }.uniq
      break if urls.size >= MAX_IMAGE_SIZE
      break if posts.size >= 200
      break if posts.size == offset
      offset = posts.size
    end
    urls.slice(0, 45)
  rescue Tumblife::NotFound
    []
  end
end
