require 'set'
require 'vcr/util/hooks'

module VCR
  # @private
  class RequestIgnorer
    include VCR::Hooks

    define_hook :ignore_request

    LOCALHOST_ALIASES = %w( localhost 127.0.0.1 0.0.0.0 )

    def initialize
      ignore_request do |request|
        host = request.parsed_uri.host
        ignored_hosts.include?(host)
      end
    end

    def ignore_localhost=(value)
      if value
        ignore_hosts(*LOCALHOST_ALIASES)
      else
        ignored_hosts.reject! { |h| LOCALHOST_ALIASES.include?(h) }
      end
    end

    def localhost_ignored?
      (LOCALHOST_ALIASES & ignore_hosts.to_a).any?
    end

    def ignore_hosts(*hosts)
      ignored_hosts.merge(hosts)
    end

    def unignore_hosts(*hosts)
      ignored_hosts.subtract(hosts)
    end

    def ignore?(request)
      invoke_hook(:ignore_request, request).any?
    end

  private

    def ignored_hosts
      @ignored_hosts ||= Set.new
    end
  end
end
