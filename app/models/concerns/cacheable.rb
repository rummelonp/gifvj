module Cacheable
  extend ActiveSupport::Concern

  NAMESPACE = 'gifvj'

  def self.cache
    @cache ||= Redis::Store.new(namespace: NAMESPACE)
  end

  included do
    def self.cache
      Cacheable.cache
    end
  end

  def cache
    Cacheable.cache
  end
end
