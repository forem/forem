module FastlyConfig
  module Errors
    class Error < StandardError
    end

    class InvalidConfigsFormat < Error
      def initialize(msg = I18n.t("errors.fastly_config.must_be_array"))
        super(msg)
      end
    end

    class InvalidConfig < Error
      def initialize(invalid_config, valid_configs)
        msg = I18n.t("errors.fastly_config.invalid_config", invalid_config: invalid_config,
                                                            valid_configs_join: valid_configs.join(", "))
        super(msg)
      end
    end
  end
end
