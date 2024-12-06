module VCR
  # @deprecated Use #configure instead.
  # @see #configure
  def config
    warn "WARNING: `VCR.config` is deprecated.  Use VCR.configure instead."
    configure { |c| yield c }
  end

  # @private
  def self.const_missing(const)
    return super unless const == :Config
    warn "WARNING: `VCR::Config` is deprecated.  Use VCR.configuration instead."
    configuration
  end

  # @private
  def Cassette.const_missing(const)
    return super unless const == :MissingERBVariableError
    warn "WARNING: `VCR::Cassette::MissingERBVariableError` is deprecated.  Use `VCR::Errors::MissingERBVariableError` instead."
    Errors::MissingERBVariableError
  end

  class Configuration
    # @deprecated Use #hook_into instead.
    # @see #hook_into
    def stub_with(*adapters)
      warn "WARNING: `VCR.configure { |c| c.stub_with ... }` is deprecated. Use `VCR.configure { |c| c.hook_into ... }` instead."
      hook_into(*adapters)
    end
  end

  # @private
  module Deprecations
    module Middleware
      # @private
      module Faraday
        def initialize(*args)
          if block_given?
            Kernel.warn "WARNING: Passing a block to `VCR::Middleware::Faraday` is deprecated. \n" +
                        "As of VCR 2.0, you need to wrap faraday requests in VCR.use_cassette, just like with any other library hook."
          end
        end
      end
    end
  end
end

