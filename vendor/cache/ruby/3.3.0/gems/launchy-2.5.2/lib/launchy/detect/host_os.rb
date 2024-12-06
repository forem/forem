require 'rbconfig'

module Launchy::Detect
  class HostOs

    attr_reader :host_os
    alias to_s host_os
    alias to_str host_os

    def initialize( host_os = nil )
      @host_os = host_os

      if not @host_os then
        if @host_os = override_host_os then
          Launchy.log "Using LAUNCHY_HOST_OS override value of '#{Launchy.host_os}'"
        else
          @host_os = default_host_os
        end
      end
    end

    def default_host_os
      ::RbConfig::CONFIG['host_os']
    end

    def override_host_os
      Launchy.host_os
    end

  end

end
