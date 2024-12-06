# frozen_string_literal: true

require_relative '../errors'

class Redis
  class Cluster
    # Keep client list of node for Redis Cluster Client
    class Node
      include Enumerable

      ReloadNeeded = Class.new(StandardError)

      ROLE_SLAVE = 'slave'

      def initialize(options, node_flags = {}, with_replica = false)
        @with_replica = with_replica
        @node_flags = node_flags
        @clients = build_clients(options)
      end

      def each(&block)
        @clients.values.each(&block)
      end

      def sample
        @clients.values.sample
      end

      def find_by(node_key)
        @clients.fetch(node_key)
      rescue KeyError
        raise ReloadNeeded
      end

      def call_all(command, &block)
        try_map { |_, client| client.call(command, &block) }.values
      end

      def call_master(command, &block)
        try_map do |node_key, client|
          next if slave?(node_key)

          client.call(command, &block)
        end.values
      end

      def call_slave(command, &block)
        return call_master(command, &block) if replica_disabled?

        try_map do |node_key, client|
          next if master?(node_key)

          client.call(command, &block)
        end.values
      end

      def process_all(commands, &block)
        try_map { |_, client| client.process(commands, &block) }.values
      end

      def scale_reading_clients
        reading_clients = []

        @clients.each do |node_key, client|
          next unless replica_disabled? ? master?(node_key) : slave?(node_key)

          reading_clients << client
        end

        reading_clients
      end

      private

      def replica_disabled?
        !@with_replica
      end

      def master?(node_key)
        !slave?(node_key)
      end

      def slave?(node_key)
        @node_flags[node_key] == ROLE_SLAVE
      end

      def build_clients(options)
        clients = options.map do |node_key, option|
          next if replica_disabled? && slave?(node_key)

          option = option.merge(readonly: true) if slave?(node_key)

          client = Client.new(option)
          [node_key, client]
        end

        clients.compact.to_h
      end

      def try_map
        errors = {}
        results = {}

        @clients.each do |node_key, client|
          begin
            reply = yield(node_key, client)
            results[node_key] = reply unless reply.nil?
          rescue CommandError => err
            errors[node_key] = err
            next
          end
        end

        return results if errors.empty?

        raise CommandErrorCollection, errors
      end
    end
  end
end
