module FastlyConfig
  module Errors
    class Error < StandardError
    end

    class InvalidConfigsFormat < Error
      def initialize(msg = I18n.t("errors.fastly_config.configs_must_be_an_array_o"))
        super(msg)
      end
    end

    class InvalidConfig < Error
      def initialize(invalid_config, valid_configs)
        msg = I18n.t("errors.fastly_config.invalid_fastly_config_only", invalid_config: invalid_config,
                                                                        valid_configs_join: valid_configs.join(", "))
        super(msg)
      end
    end
  end
end
