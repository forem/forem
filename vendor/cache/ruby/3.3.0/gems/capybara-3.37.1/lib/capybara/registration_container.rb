# frozen_string_literal: true

module Capybara
  # @api private
  class RegistrationContainer
    def names
      @registered.keys
    end

    def [](name)
      @registered[name]
    end

    def []=(name, value)
      Capybara::Helpers.warn 'DEPRECATED: Directly setting drivers/servers is deprecated, please use Capybara.register_driver/register_server instead'
      @registered[name] = value
    end

    def method_missing(method_name, *args, **options, &block)
      if @registered.respond_to?(method_name)
        Capybara::Helpers.warn "DEPRECATED: Calling '#{method_name}' on the drivers/servers container is deprecated without replacement"
        return @registered.public_send(method_name, *args, **options, &block)
      end
      super
    end

    def respond_to_missing?(method_name, include_all)
      @registered.respond_to?(method_name) || super
    end

  private

    def initialize
      @registered = {}
    end

    def register(name, block)
      @registered[name] = block
    end
  end
end
