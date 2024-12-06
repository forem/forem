require "guard/ui"

module Guard
  # This class contains useful methods to:
  #
  # * Fetch all the Guard plugins names;
  # * Initialize a plugin, get its location;
  # * Return its class name;
  # * Add its template to the Guardfile.
  #
  class PluginUtil
    ERROR_NO_GUARD_OR_CLASS = "Could not load 'guard/%s' or" \
      " find class Guard::%s"

    INFO_ADDED_GUARD_TO_GUARDFILE = "%s guard added to Guardfile,"\
      " feel free to edit it"

    attr_accessor :name

    # Returns a list of Guard plugin Gem names installed locally.
    #
    # @return [Array<String>] a list of Guard plugin gem names
    #
    def self.plugin_names
      valid = Gem::Specification.find_all.select do |gem|
        _gem_valid?(gem)
      end

      valid.map { |x| x.name.sub(/^guard-/, "") }.uniq
    end

    # Initializes a new `Guard::PluginUtil` object.
    #
    # @param [String] name the name of the Guard plugin
    #
    def initialize(name)
      @name = name.to_s.sub(/^guard-/, "")
    end

    # Initializes a new `Guard::Plugin` with the given `options` hash. This
    # methods handles plugins that inherit from the deprecated `Guard::Guard`
    # class as well as plugins that inherit from `Guard::Plugin`.
    #
    # @see Guard::Plugin
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
    # upgrade for Guard 2.0
    #
    # @return [Guard::Plugin] the initialized plugin
    # @return [Guard::Guard] the initialized plugin. This return type is
    #   deprecated and the plugin's maintainer should update it to be
    #   compatible with Guard 2.0. For more information on how to upgrade for
    #   Guard 2.0, please head over to:
    #   https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0
    #
    def initialize_plugin(options)
      klass = plugin_class
      fail "Could not load class: #{_constant_name.inspect}" unless klass
      if klass.ancestors.include?(Guard)
        klass.new(options.delete(:watchers), options)
      else
        begin
          klass.new(**options)
        rescue ArgumentError => e
          fail "Failed to call #{klass}.new(options): #{e}"
        end
      end
    end

    # Locates a path to a Guard plugin gem.
    #
    # @return [String] the full path to the plugin gem
    #
    def plugin_location
      @plugin_location ||= _full_gem_path("guard-#{name}")
    rescue Gem::LoadError
      UI.error "Could not find 'guard-#{ name }' gem path."
    end

    # Tries to load the Guard plugin main class. This transforms the supplied
    # plugin name into a class name:
    #
    # * `guardname` will become `Guard::Guardname`
    # * `dashed-guard-name` will become `Guard::DashedGuardName`
    # * `underscore_guard_name` will become `Guard::UnderscoreGuardName`
    #
    # When no class is found with the strict case sensitive rules, another
    # try is made to locate the class without matching case:
    #
    # * `rspec` will find a class `Guard::RSpec`
    #
    # @option options [Boolean] fail_gracefully whether error messages should
    # not be printed
    #
    # @return [Class, nil] the loaded class
    #
    def plugin_class(options = {})
      options = { fail_gracefully: false }.merge(options)

      const = _plugin_constant
      fail TypeError, "no constant: #{_constant_name}" unless const
      @plugin_class ||= Guard.const_get(const)

    rescue TypeError
      begin
        require "guard/#{ name.downcase }"
        const = _plugin_constant
        @plugin_class ||= Guard.const_get(const)

      rescue TypeError => error
        UI.error "Could not find class Guard::#{ _constant_name }"
        UI.error error.backtrace.join("\n")
        # TODO: return value or move exception higher
      rescue LoadError => error
        unless options[:fail_gracefully]
          msg = format(ERROR_NO_GUARD_OR_CLASS, name.downcase, _constant_name)
          UI.error(msg)
          UI.error("Error is: #{error}")
          UI.error(error.backtrace.join("\n"))
          # TODO: return value or move exception higher
        end
      end
    end

    # Adds a plugin's template to the Guardfile.
    #
    def add_to_guardfile
      klass = plugin_class # call here to avoid failing later

      require_relative "guardfile/evaluator"
      # TODO: move this to Generator?
      options = Guard.state.session.evaluator_options
      evaluator = Guardfile::Evaluator.new(options)
      begin
        evaluator.evaluate
      rescue Guard::Guardfile::Evaluator::NoPluginsError
      end

      if evaluator.guardfile_include?(name)
        UI.info "Guardfile already includes #{ name } guard"
      else
        content = File.read("Guardfile")
        File.open("Guardfile", "wb") do |f|
          f.puts(content)
          f.puts("")
          f.puts(klass.template(plugin_location))
        end

        UI.info INFO_ADDED_GUARD_TO_GUARDFILE % name
      end
    end

    private

    # Returns the constant for the current plugin.
    #
    # @example Returns the constant for a plugin
    #   > Guard::PluginUtil.new('rspec').send(:_plugin_constant)
    #   => Guard::RSpec
    #
    def _plugin_constant
      @_plugin_constant ||= Guard.constants.detect do |c|
        c.to_s.casecmp(_constant_name.downcase).zero?
      end
    end

    # Guesses the most probable name for the current plugin based on its name.
    #
    # @example Returns the most probable name for a plugin
    #   > Guard::PluginUtil.new('rspec').send(:_constant_name)
    #   => "Rspec"
    #
    def _constant_name
      @_constant_name ||= name.gsub(%r{/(.?)}) { "::#{ $1.upcase }" }.
                          gsub(/(?:^|[_-])(.)/) { $1.upcase }
    end

    def _full_gem_path(name)
      Gem::Specification.find_by_name(name).full_gem_path
    end

    class << self
      def _gem_valid?(gem)
        return false if gem.name == "guard-compat"
        return true if gem.name =~ /^guard-/
        full_path = gem.full_gem_path
        file = File.join(full_path, "lib", "guard", "#{gem.name}.rb")
        File.exist?(file)
      end
    end
  end
end
