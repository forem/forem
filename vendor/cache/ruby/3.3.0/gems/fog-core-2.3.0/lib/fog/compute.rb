module Fog
  module Compute
    extend Fog::ServicesMixin

    def self.new(orig_attributes)
      attributes = orig_attributes.dup # prevent delete from having side effects
      provider = attributes.delete(:provider).to_s.downcase.to_sym

      case provider
      when :rackspace
        version = attributes.delete(:version)
        version = version.to_s.downcase.to_sym unless version.nil?
        if version == :v1
          Fog::Logger.deprecation "First Gen Cloud Servers are deprecated. Please use `:version => :v2` attribute to use Next Gen Cloud Servers."
          require "fog/rackspace/compute"
          Fog::Compute::Rackspace.new(attributes)
        else
          require "fog/rackspace/compute_v2"
          Fog::Compute::RackspaceV2.new(attributes)
        end
      when :digitalocean
        version = attributes.delete(:version)
        version = version.to_s.downcase.to_sym unless version.nil?
        if version == :v1
          error_message = 'DigitalOcean V1 is deprecated.Please use `:version => :v2` attribute to use Next Gen Cloud Servers.'
          raise error_message
        else
          require 'fog/digitalocean/compute'
          Fog::Compute::DigitalOcean.new(attributes)
        end
      else
        super(orig_attributes)
      end
    end

    def self.servers
      servers = []
      providers.each do |provider|
        begin
          servers.concat(self[provider].servers)
        rescue # ignore any missing credentials/etc
        end
      end
      servers
    end
  end
end
