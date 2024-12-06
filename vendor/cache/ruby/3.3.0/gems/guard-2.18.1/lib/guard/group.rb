module Guard
  # A group of Guard plugins. There are two reasons why you want to group your
  # Guard plugins:
  #
  # * You can start only certain groups from the command line by passing the
  #   `--group` option to `guard start`.
  # * Abort task execution chain on failure within a group with the
  #   `:halt_on_fail` option.
  #
  # @example Group that aborts on failure
  #
  #   group :frontend, halt_on_fail: true do
  #     guard 'coffeescript', input: 'spec/coffeescripts',
  #       output: 'spec/javascripts'
  #     guard 'jasmine-headless-webkit' do
  #       watch(%r{^spec/javascripts/(.*)\..*}) do |m|
  #       newest_js_file("spec/javascripts/#{m[1]}_spec")
  #     end
  #     end
  #   end
  #
  # @see Guard::CLI
  #
  class Group
    attr_accessor :name, :options

    # Initializes a Group.
    #
    # @param [String] name the name of the group
    # @param [Hash] options the group options
    # @option options [Boolean] halt_on_fail if a task execution
    #   should be halted for all Guard plugins in this group if a Guard plugin
    #   throws `:task_has_failed`
    #
    def initialize(name, options = {})
      @name = name.to_sym
      @options = options
    end

    # Returns the group title.
    #
    # @example Title for a group named 'backend'
    #   > Guard::Group.new('backend').title
    #   => "Backend"
    #
    # @return [String]
    #
    def title
      @title ||= name.to_s.capitalize
    end

    # String representation of the group.
    #
    # @example String representation of a group named 'backend'
    #   > Guard::Group.new('backend').to_s
    #   => "#<Guard::Group @name=backend @options={}>"
    #
    # @return [String] the string representation
    #
    def to_s
      "#<#{self.class} @name=#{name} @options=#{options}>"
    end
  end
end
