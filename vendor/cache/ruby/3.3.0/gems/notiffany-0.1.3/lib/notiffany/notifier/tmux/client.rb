require "shellany/sheller"

module Notiffany
  class Notifier
    class Tmux < Base
      # Class for actually calling TMux to run commands
      class Client
        CLIENT = "tmux".freeze

        class << self
          def version
            begin
              Float(_capture("-V")[/\d+\.\d+/])
            rescue NoMethodError, TypeError
              raise Base::UnavailableError, "Could not find tmux"
            end
          end

          def _capture(*args)
            Shellany::Sheller.stdout(([CLIENT] + args).join(" "))
          end

          def _run(*args)
            Shellany::Sheller.run(([CLIENT] + args).join(" "))
          end
        end

        def initialize(client)
          @client = client
        end

        def clients
          return [@client] unless @client == :all
          ttys = _capture("list-clients", "-F", "'\#{client_tty}'")
          ttys = ttys.split(/\n/)

          # if user is running 'tmux -C' remove this client from list
          ttys.delete("(null)")
          ttys
        end

        def set(key, value)
          clients.each do |client|
            args = client ? ["-t", client.strip] : nil
            _run("set", "-q", *args, key, value)
          end
        end

        def display_message(message)
          clients.each do |client|
            args = ["-c", client.strip] if client
            # TODO: should properly escape message here
            _run("display", *args, "'#{message}'")
          end
        end

        def unset(key, value)
          clients.each do |client|
            _run(*_all_args_for(key, value, client))
          end
        end

        def parse_options
          output = _capture("show", "-t", @client)
          Hash[output.lines.map { |line| _parse_option(line) }]
        end

        def message_fg=(color)
          set("message-fg", color)
        end

        def message_bg=(color)
          set("message-bg", color)
        end

        def display_time=(time)
          set("display-time", time)
        end

        def title=(string)
          # TODO: properly escape?
          set("set-titles-string", "'#{string}'")
        end

        private

        def _run(*args)
          self.class._run(*args)
        end

        def _capture(*args)
          self.class._capture(*args)
        end

        def _parse_option(line)
          line.partition(" ").map(&:strip).reject(&:empty?)
        end

        def _all_args_for(key, value, client)
          unset = value ? [] : %w(-u)
          args = client ? ["-t", client.strip] : []
          ["set", "-q", *unset, *args, key, *[value].compact]
        end
      end
    end
  end
end
