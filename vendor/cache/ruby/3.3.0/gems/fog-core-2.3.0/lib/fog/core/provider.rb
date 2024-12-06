module Fog
  class << self
    attr_writer :providers
  end

  def self.providers
    @providers ||= {}
  end

  module Provider
    class << self
      def extended(base)
        provider = base.to_s.split("::").last
        Fog.providers[provider.downcase.to_sym] = provider
        Fog.providers[underscore_name(provider).to_sym] = provider
      end
    
      private

      def underscore_name(string)
        string.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end
    end

    def [](service_key)
      eval(@services_registry[service_key]).new
    end

    def service(new_service, constant_string)
      Fog.services[new_service] ||= []
      Fog.services[new_service] |= [to_s.split("::").last.downcase.to_sym]
      @services_registry ||= {}
      @services_registry[new_service] = service_klass(constant_string)
    end

    def services
      @services_registry.keys
    end

    # Returns service constant path, with provider, as string. If
    # "provider::service" is defined (the preferred format) then it returns that
    # string, otherwise it returns the deprecated string "service::provider".
    def service_klass(constant_string)
      if const_defined?([to_s, constant_string].join("::"))
        [to_s, constant_string].join("::")
      else
        provider = to_s.split("::").last
        Fog::Logger.deprecation("Unable to load #{[to_s, constant_string].join("::")}")
        Fog::Logger.deprecation(
          format(
            Fog::ServicesMixin::E_SERVICE_PROVIDER_CONSTANT,
            service: constant_string,
            provider: provider
          )
        )
        ['Fog', constant_string, provider].join("::")
      end
    end
  end
end
