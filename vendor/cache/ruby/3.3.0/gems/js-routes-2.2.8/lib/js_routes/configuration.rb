require "pathname"

module JsRoutes
  class Configuration
    DEFAULTS = {
      namespace: nil,
      exclude: [],
      include: //,
      file: nil,
      prefix: -> { Rails.application.config.relative_url_root || "" },
      url_links: false,
      camel_case: false,
      default_url_options: {},
      compact: false,
      serializer: nil,
      special_options_key: "_options",
      application: -> { Rails.application },
      module_type: 'ESM',
      documentation: true,
    } #:nodoc:

    attr_accessor(*DEFAULTS.keys)

    def initialize(attributes = nil)
      assign(DEFAULTS)
      return unless attributes
      assign(attributes)
    end

    def assign(attributes = nil, &block)
      if !attributes && !block
        raise "Provide attributes or block"
      end
      tap(&block) if block
      if attributes
        attributes.each do |attribute, value|
          value = value.call if value.is_a?(Proc)
          send(:"#{attribute}=", value)
        end
      end
      normalize_and_verify
      self
    end

    def [](attribute)
      send(attribute)
    end

    def merge(attributes)
      clone.assign(attributes)
    end

    def to_hash
      Hash[*members.zip(values).flatten(1)].symbolize_keys
    end

    def esm?
      module_type === 'ESM'
    end

    def dts?
      self.module_type === 'DTS'
    end

    def modern?
      esm? || dts?
    end

    def require_esm
      raise "ESM module type is required" unless modern?
    end

    def source_file
      File.dirname(__FILE__) + "/../" + default_file_name
    end

    def output_file
      webpacker_dir = defined?(Webpacker) ? Webpacker.config.source_path : pathname('app', 'javascript')
      sprockets_dir = pathname('app','assets','javascripts')
      file_name = file || default_file_name
      sprockets_file = sprockets_dir.join(file_name)
      webpacker_file = webpacker_dir.join(file_name)
      !Dir.exist?(webpacker_dir) && defined?(::Sprockets) ? sprockets_file : webpacker_file
    end

    protected

    def normalize_and_verify
      normalize
      verify
    end

    def pathname(*parts)
      Pathname.new(File.join(*parts))
    end

    def default_file_name
      dts? ? "routes.d.ts" : "routes.js"
    end

    def normalize
      self.module_type = module_type&.upcase || 'NIL'
    end

    def verify
      if module_type != 'NIL' && namespace
        raise "JsRoutes namespace option can only be used if module_type is nil"
      end
    end
  end
end
