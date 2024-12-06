require "thor/core_ext/hash_with_indifferent_access"

module Guard
  # A class that holds options. Can be instantiated with default options.
  #
  class Options < Thor::CoreExt::HashWithIndifferentAccess
    # Initializes an Guard::Options object. `default_opts` is merged into
    # `opts`.
    #
    # @param [Hash] opts the options
    # @param [Hash] default_opts the default options
    #
    def initialize(opts = {}, default_opts = {})
      super(default_opts.merge(opts || {}))
    end

    # workaround for: https://github.com/erikhuda/thor/issues/504
    def fetch(name)
      super(name.to_s)
    end
  end
end
