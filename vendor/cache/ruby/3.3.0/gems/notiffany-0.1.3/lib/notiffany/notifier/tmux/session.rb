module Notiffany
  class Notifier
    class Tmux < Base
      # Preserves TMux settings for all tmux sessions
      class Session
        def initialize
          @options_store = {}

          # NOTE: we are reading the settings of all clients
          # - regardless of the :display_on_all_clients option

          # Ideally, this should be done incrementally (e.g. if we start with
          # "current" client and then override the :display_on_all_clients to
          # true, only then the option store should be updated to contain
          # settings of all clients
          Client.new(:all).clients.each do |client|
            @options_store[client] = {
              "status-left-bg"  => nil,
              "status-right-bg" => nil,
              "status-left-fg"  => nil,
              "status-right-fg" => nil,
              "message-bg"      => nil,
              "message-fg"      => nil,
              "display-time"    => nil
            }.merge(Client.new(client).parse_options)
          end
        end

        def close
          @options_store.each do |client, options|
            options.each do |key, value|
              Client.new(client).unset(key, value)
            end
          end
          @options_store = nil
        end
      end
    end
  end
end
