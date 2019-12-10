module CacheBuster
  class BustPathJob < ApplicationJob
    queue_as :bust_path

    def perform(path, cache_buster = CacheBuster)
      cache_buster.bust(path)
    end
  end
end
