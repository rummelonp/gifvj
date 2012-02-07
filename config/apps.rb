# -*- coding: utf-8 -*-

Padrino.configure_apps do
end

Tumblife.configure do |config|
  config.consumer_key = '*** consumer key ***'
end

# Enable logging
Padrino::Logger::Config[:development] = {log_level: :debug, stream: :stdout}
Padrino::Logger::Config[:production] = {log_level: :info, stream: :to_file}

# Mounts the core application for this project
Padrino.mount("GifVJ").to('/')
