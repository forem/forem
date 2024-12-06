module FakeRedis
  TRANSACTION_COMMANDS = [:discard, :exec, :multi, :watch, :unwatch, :client]

  module TransactionCommands
    def self.included(klass)
      klass.class_eval do
        def self.queued_commands
          @queued_commands ||= Hash.new {|h,k| h[k] = [] }
        end

        def self.in_multi
          @in_multi ||= Hash.new{|h,k| h[k] = false}
        end

        def queued_commands
          self.class.queued_commands[database_instance_key]
        end

        def queued_commands=(cmds)
          self.class.queued_commands[database_instance_key] = cmds
        end

        def in_multi
          self.class.in_multi[database_instance_key]
        end

        def in_multi=(multi_state)
          self.class.in_multi[database_instance_key] = multi_state
        end
      end
    end

    def discard
      unless in_multi
        raise Redis::CommandError, "ERR DISCARD without MULTI"
      end

      self.in_multi = false
      self.queued_commands = []

      'OK'
    end

    def exec
      unless in_multi
        raise Redis::CommandError, "ERR EXEC without MULTI"
      end

      responses  = queued_commands.map do |cmd|
        begin
          send(*cmd)
        rescue => e
          e
        end
      end

      self.queued_commands = [] # reset queued_commands
      self.in_multi = false     # reset in_multi state

      responses
    end

    def multi
      if in_multi
        raise Redis::CommandError, "ERR MULTI calls can not be nested"
      end

      self.in_multi = true

      yield(self) if block_given?

      "OK"
    end

    def watch(*_)
      "OK"
    end

    def unwatch
      "OK"
    end
  end
end
