require "guard"
require "guard/internals/groups"

module Guard
  # Base class from which every Guard plugin implementation must inherit.
  #
  # Guard will trigger the {#start}, {#stop}, {#reload}, {#run_all} and
  # {#run_on_changes} ({#run_on_additions}, {#run_on_modifications} and
  # {#run_on_removals}) task methods depending on user interaction and file
  # modification.
  #
  # {#run_on_changes} could be implemented to handle all the changes task case
  # (additions, modifications, removals) in once, or each task can be
  # implemented separately with a specific behavior.
  #
  # In each of these Guard task methods you have to implement some work when
  # you want to support this kind of task. The return value of each Guard task
  # method is not evaluated by Guard, but it'll be passed to the "_end" hook
  # for further evaluation. You can throw `:task_has_failed` to indicate that
  # your Guard plugin method was not successful, and successive Guard plugin
  # tasks will be aborted when the group has set the `:halt_on_fail` option.
  #
  # @see Guard::Group
  #
  # @example Throw :task_has_failed
  #
  #   def run_all
  #     if !runner.run(['all'])
  #       throw :task_has_failed
  #     end
  #   end
  #
  # Each Guard plugin should provide a template Guardfile located within the Gem
  # at `lib/guard/guard-name/templates/Guardfile`.
  #
  # Watchers for a Guard plugin should return a file path or an array of files
  # paths to Guard, but if your Guard plugin wants to allow any return value
  # from a watcher, you can set the `any_return` option to true.
  #
  # If one of those methods raises an exception other than `:task_has_failed`,
  # the `Guard::GuardName` instance will be removed from the active Guard
  # plugins.
  #
  class Plugin
    TEMPLATE_FORMAT = "%s/lib/guard/%s/templates/Guardfile"

    require "guard/ui"

    # Get all callbacks registered for all Guard plugins present in the
    # Guardfile.
    #
    def self.callbacks
      @callbacks ||= Hash.new { |hash, key| hash[key] = [] }
    end

    # Add a callback.
    #
    # @param [Block] listener the listener to notify
    # @param [Guard::Plugin] guard_plugin the Guard plugin to add the callback
    # @param [Array<Symbol>] events the events to register
    #
    def self.add_callback(listener, guard_plugin, events)
      Array(events).each do |event|
        callbacks[[guard_plugin, event]] << listener
      end
    end

    # Notify a callback.
    #
    # @param [Guard::Plugin] guard_plugin the Guard plugin to add the callback
    # @param [Symbol] event the event to trigger
    # @param [Array] args the arguments for the listener
    #
    def self.notify(guard_plugin, event, *args)
      callbacks[[guard_plugin, event]].each do |listener|
        listener.call(guard_plugin, event, *args)
      end
    end

    # Reset all callbacks.
    #
    # TODO: remove (not used anywhere)
    def self.reset_callbacks!
      @callbacks = nil
    end

    # When event is a Symbol, {#hook} will generate a hook name
    # by concatenating the method name from where {#hook} is called
    # with the given Symbol.
    #
    # @example Add a hook with a Symbol
    #
    #   def run_all
    #     hook :foo
    #   end
    #
    # Here, when {Guard::Plugin#run_all} is called, {#hook} will notify
    # callbacks registered for the "run_all_foo" event.
    #
    # When event is a String, {#hook} will directly turn the String
    # into a Symbol.
    #
    # @example Add a hook with a String
    #
    #   def run_all
    #     hook "foo_bar"
    #   end
    #
    # When {Guard::Plugin::run_all} is called, {#hook} will notify
    # callbacks registered for the "foo_bar" event.
    #
    # @param [Symbol, String] event the name of the Guard event
    # @param [Array] args the parameters are passed as is to the callbacks
    #   registered for the given event.
    #
    def hook(event, *args)
      hook_name = if event.is_a? Symbol
                    calling_method = caller[0][/`([^']*)'/, 1]
                    "#{ calling_method }_#{ event }"
                  else
                    event
                  end

      UI.debug "Hook :#{ hook_name } executed for #{ self.class }"

      self.class.notify(self, hook_name.to_sym, *args)
    end

    attr_accessor :group, :watchers, :callbacks, :options

    # Returns the non-namespaced class name of the plugin
    #
    #
    # @example Non-namespaced class name for Guard::RSpec
    #   Guard::RSpec.non_namespaced_classname
    #   #=> "RSpec"
    #
    # @return [String]
    #
    def self.non_namespaced_classname
      to_s.sub("Guard::", "")
    end

    # Returns the non-namespaced name of the plugin
    #
    #
    # @example Non-namespaced name for Guard::RSpec
    #   Guard::RSpec.non_namespaced_name
    #   #=> "rspec"
    #
    # @return [String]
    #
    def self.non_namespaced_name
      non_namespaced_classname.downcase
    end

    # Specify the source for the Guardfile template.
    # Each Guard plugin can redefine this method to add its own logic.
    #
    # @param [String] plugin_location the plugin location
    #
    def self.template(plugin_location)
      File.read(format(TEMPLATE_FORMAT, plugin_location, non_namespaced_name))
    end

    # Called once when Guard starts. Please override initialize method to
    # init stuff.
    #
    # @raise [:task_has_failed] when start has failed
    # @return [Object] the task result
    #
    # @!method start

    # Called when `stop|quit|exit|s|q|e + enter` is pressed (when Guard
    # quits).
    #
    # @raise [:task_has_failed] when stop has failed
    # @return [Object] the task result
    #
    # @!method stop

    # Called when `reload|r|z + enter` is pressed.
    # This method should be mainly used for "reload" (really!) actions like
    # reloading passenger/spork/bundler/...
    #
    # @raise [:task_has_failed] when reload has failed
    # @return [Object] the task result
    #
    # @!method reload

    # Called when just `enter` is pressed
    # This method should be principally used for long action like running all
    # specs/tests/...
    #
    # @raise [:task_has_failed] when run_all has failed
    # @return [Object] the task result
    #
    # @!method run_all

    # Default behaviour on file(s) changes that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_changes has failed
    # @return [Object] the task result
    #
    # @!method run_on_changes(paths)

    # Called on file(s) additions that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_additions has failed
    # @return [Object] the task result
    #
    # @!method run_on_additions(paths)

    # Called on file(s) modifications that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_modifications has failed
    # @return [Object] the task result
    #
    # @!method run_on_modifications(paths)

    # Called on file(s) removals that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_removals has failed
    # @return [Object] the task result
    #
    # @!method run_on_removals(paths)

    # Returns the plugin's name (without "guard-").
    #
    # @example Name for Guard::RSpec
    #   Guard::RSpec.new.name
    #   #=> "rspec"
    #
    # @return [String]
    #
    def name
      @name ||= self.class.non_namespaced_name
    end

    # Returns the plugin's class name without the Guard:: namespace.
    #
    # @example Title for Guard::RSpec
    #   Guard::RSpec.new.title
    #   #=> "RSpec"
    #
    # @return [String]
    #
    def title
      @title ||= self.class.non_namespaced_classname
    end

    # String representation of the plugin.
    #
    # @example String representation of an instance of the Guard::RSpec plugin
    #
    #   Guard::RSpec.new.title
    #   #=> "#<Guard::RSpec @name=rspec @group=#<Guard::Group @name=default
    #   @options={}> @watchers=[] @callbacks=[] @options={all_after_pass:
    #   true}>"
    #
    # @return [String] the string representation
    #
    def to_s
      "#<#{self.class} @name=#{name} @group=#{group} @watchers=#{watchers}"\
        " @callbacks=#{callbacks} @options=#{options}>"
    end

    private

    # Initializes a Guard plugin.
    # Don't do any work here, especially as Guard plugins get initialized even
    # if they are not in an active group!
    #
    # @param [Hash] options the Guard plugin options
    # @option options [Array<Guard::Watcher>] watchers the Guard plugin file
    #   watchers
    # @option options [Symbol] group the group this Guard plugin belongs to
    # @option options [Boolean] any_return allow any object to be returned from
    #   a watcher
    #
    def initialize(options = {})
      group_name = options.delete(:group) { :default }
      @group = Guard.state.session.groups.add(group_name)
      @watchers = options.delete(:watchers) { [] }
      @callbacks = options.delete(:callbacks) { [] }
      @options = options
      _register_callbacks
    end

    # Add all the Guard::Plugin's callbacks to the global @callbacks array
    # that's used by Guard to know which callbacks to notify.
    #
    def _register_callbacks
      callbacks.each do |callback|
        self.class.add_callback(callback[:listener], self, callback[:events])
      end
    end
  end
end
