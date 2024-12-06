# frozen_string_literal: true

class Redis
  module Commands
    module Cluster
      # Sends `CLUSTER *` command to random node and returns its reply.
      #
      # @see https://redis.io/commands#cluster Reference of cluster command
      #
      # @param subcommand [String, Symbol] the subcommand of cluster command
      #   e.g. `:slots`, `:nodes`, `:slaves`, `:info`
      #
      # @return [Object] depends on the subcommand
      def cluster(subcommand, *args)
        subcommand = subcommand.to_s.downcase
        block = case subcommand
        when 'slots'
          HashifyClusterSlots
        when 'nodes'
          HashifyClusterNodes
        when 'slaves'
          HashifyClusterSlaves
        when 'info'
          HashifyInfo
        else
          Noop
        end

        # @see https://github.com/antirez/redis/blob/unstable/src/redis-trib.rb#L127 raw reply expected
        block = Noop unless @cluster_mode

        send_command([:cluster, subcommand] + args, &block)
      end

      # Sends `ASKING` command to random node and returns its reply.
      #
      # @see https://redis.io/topics/cluster-spec#ask-redirection ASK redirection
      #
      # @return [String] `'OK'`
      def asking
        send_command(%i[asking])
      end
    end
  end
end
