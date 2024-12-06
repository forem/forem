module Twitter
  class Arguments < Array
    # @return [Hash]
    attr_reader :options

    # Initializes a new Arguments object
    #
    # @return [Twitter::Arguments]
    def initialize(args)
      @options = args.last.is_a?(::Hash) ? args.pop : {}
      super(args.flatten)
    end
  end
end
