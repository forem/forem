require "lumberjack"

require "guard/ui"
require "guard/watcher"

module Guard
  # The runner is responsible for running all methods defined on each plugin.
  #
  class Runner
    # Runs a Guard-task on all registered plugins.
    #
    # @param [Symbol] task the task to run
    #
    # @param [Hash] scope_hash either the Guard plugin or the group to run the task
    # on
    #
    def run(task, scope_hash = {})
      Lumberjack.unit_of_work do
        items = Guard.state.scope.grouped_plugins(scope_hash || {})
        items.each do |_group, plugins|
          _run_group_plugins(plugins) do |plugin|
            _supervise(plugin, task) if plugin.respond_to?(task)
          end
        end
      end
    end

    PLUGIN_FAILED = "%s has failed, other group's plugins will be skipped."

    MODIFICATION_TASKS = [
      :run_on_modifications, :run_on_changes, :run_on_change
    ]

    ADDITION_TASKS = [:run_on_additions, :run_on_changes, :run_on_change]
    REMOVAL_TASKS = [:run_on_removals, :run_on_changes, :run_on_deletion]

    # Runs the appropriate tasks on all registered plugins
    # based on the passed changes.
    #
    # @param [Array<String>] modified the modified paths.
    # @param [Array<String>] added the added paths.
    # @param [Array<String>] removed the removed paths.
    #
    def run_on_changes(modified, added, removed)
      types = {
        MODIFICATION_TASKS => modified,
        ADDITION_TASKS => added,
        REMOVAL_TASKS => removed
      }

      UI.clearable

      Guard.state.scope.grouped_plugins.each do |_group, plugins|
        _run_group_plugins(plugins) do |plugin|
          UI.clear
          types.each do |tasks, unmatched_paths|
            next if unmatched_paths.empty?
            match_result = Watcher.match_files(plugin, unmatched_paths)
            next if match_result.empty?
            task = tasks.detect { |meth| plugin.respond_to?(meth) }
            _supervise(plugin, task, match_result) if task
          end
        end
      end
    end

    # Run a Guard plugin task, but remove the Guard plugin when his work leads
    # to a system failure.
    #
    # When the Group has `:halt_on_fail` disabled, we've to catch
    # `:task_has_failed` here in order to avoid an uncaught throw error.
    #
    # @param [Guard::Plugin] plugin guard the Guard to execute
    # @param [Symbol] task the task to run
    # @param [Array] args the arguments for the task
    # @raise [:task_has_failed] when task has failed
    #
    def _supervise(plugin, task, *args)
      catch self.class.stopping_symbol_for(plugin) do
        plugin.hook("#{ task }_begin", *args)
        result = UI.options.with_progname(plugin.class.name) do
          begin
            plugin.send(task, *args)
          rescue Interrupt
            throw(:task_has_failed)
          end
        end
        plugin.hook("#{ task }_end", result)
        result
      end
    rescue ScriptError, StandardError, RuntimeError
      UI.error("#{ plugin.class.name } failed to achieve its"\
                        " <#{ task }>, exception was:" \
                        "\n#{ $!.class }: #{ $!.message }" \
                        "\n#{ $!.backtrace.join("\n") }")
      Guard.state.session.plugins.remove(plugin)
      UI.info("\n#{ plugin.class.name } has just been fired")
      $!
    end

    # Returns the symbol that has to be caught when running a supervised task.
    #
    # @note If a Guard group is being run and it has the `:halt_on_fail`
    #   option set, this method returns :no_catch as it will be caught at the
    #   group level.
    #
    # @param [Guard::Plugin] guard the Guard plugin to execute
    # @return [Symbol] the symbol to catch
    #
    def self.stopping_symbol_for(guard)
      guard.group.options[:halt_on_fail] ? :no_catch : :task_has_failed
    end

    private

    def _run_group_plugins(plugins)
      failed_plugin = nil
      catch :task_has_failed do
        plugins.each do |plugin|
          failed_plugin = plugin
          yield plugin
          failed_plugin = nil
        end
      end
      UI.info format(PLUGIN_FAILED, failed_plugin.class.name) if failed_plugin
    end
  end
end
