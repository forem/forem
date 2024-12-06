module Ransack
  module Naming

    def self.included(base)
      base.extend ClassMethods
    end

    def persisted?
      false
    end

    def to_key
      nil
    end

    def to_param
      nil
    end

    def to_model
      self
    end

    def model_name
      self.class.model_name
    end
  end

  class Name < String
    attr_reader :singular, :plural, :element, :collection, :partial_path,
                :human, :param_key, :route_key, :i18n_key
    alias_method :cache_key, :collection

    def initialize
      super(Constants::CAP_SEARCH)
      @singular     = Constants::SEARCH
      @plural       = Constants::SEARCHES
      @element      = Constants::SEARCH
      @human        = Constants::CAP_SEARCH
      @collection   = Constants::RANSACK_SLASH_SEARCHES
      @partial_path = Constants::RANSACK_SLASH_SEARCHES_SLASH_SEARCH
      @param_key    = Constants::Q
      @route_key    = Constants::SEARCHES
      @i18n_key     = :ransack
    end
  end

  module ClassMethods
    def model_name
      @_model_name ||= Name.new
    end

    def i18n_scope
      :ransack
    end
  end

end
