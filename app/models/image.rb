class Image
  attr_reader :url
  attr_reader :realpath
  attr_reader :path

  def initialize(url)
    @url = url
    basename = File.basename(url)
    @realpath = Rails.root + 'public/images' + basename
    @path = "/images/#{basename}"
  end

  def exist?
    realpath.exist?
  end

  def fetch
    return if exist?
    Rails.logger.info "image fetch: #{url}"
    realpath.open('wb') do |file|
      open(url, 'rb') do |data|
        file.print data.read
      end
    end
  rescue => e
    Rails.logger.warn "image fetch error: #{e.message}"
  end
end
