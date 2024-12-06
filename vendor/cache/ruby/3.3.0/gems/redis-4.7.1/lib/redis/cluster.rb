# frozen_string_literal: true

require_relative 'errors'
require_relative 'client'
require_relative 'cluster/command'
require_relative 'cluster/command_loader'
require_relative 'cluster/key_slot_converter'
require_relative 'cluster/node'
require_relative 'cluster/node_key'
require_relative 'cluster/node_loader'
require_relative 'cluster/option'
require_relative 'cluster/slot'
require_relative 'cluster/slot_loader'

class Redis
  # Redis Cluster client
  #
  # @see https://github.com/antirez/redis-rb-cluster POC implementation
  # @see https://redis.io/topics/cluster-spec Redis Cluster specification
  # @see https://redis.io/topics/cluster-tutorial Redis Cluster tutorial
  #
  # Copyright (C) 2013 Salvatore Sanfilippo <antirez@gmail.com>
  class Cluster
    def initialize(options = {})
      @option = Option.new(options)
      @node, @slot = fetch_cluster_info!(@option)
      @command = fetch_command_details(@node)
    end

    def id
      @node.map(&:id).sort.join(' ')
    end

    # db feature is disabled in cluster mode
    def db
      0
    end

    # db feature is disabled in cluster mode
    def db=(_db); end

    def timeout
      @node.first.timeout
    end

    def connected?
      @node.any?(&:connected?)
    end

    def disconnect
      @node.each(&:disconnect)
      true
    end

    def connection_info
      @node.sort_by(&:id).map do |client|
        {
          host: client.host,
          port: client.port,
          db: client.db,
          id: client.id,
          location: client.location
        }
      end
    end

    def with_reconnect(val = true, &block)
      try_send(@node.sample, :with_reconnect, val, &block)
    end

    def call(command, &block)
      send_command(command, &block)
    end

    def call_loop(command, timeout = 0, &block)
      node = assign_node(command)
      try_send(node, :call_loop, command, timeout, &block)
    end

    def call_pipeline(pipeline)
      node_keys = pipeline.commands.map { |cmd| find_node_key(cmd, primary_only: true) }.compact.uniq
      if node_keys.size > 1
        raise(CrossSlotPipeliningError,
              pipeline.commands.map { |cmd| @command.extract_first_key(cmd) }.reject(&:empty?).uniq)
      end

      try_send(find_node(node_keys.first), :call_pipeline, pipeline)
    end

    def call_with_timeout(command, timeout, &block)
      node = assign_node(command)
      try_send(node, :call_with_timeout, command, timeout, &block)
    end

    def call_without_timeout(command, &block)
      call_with_timeout(command, 0, &block)
    end

    def process(commands, &block)
      if commands.size == 1 &&
         %w[unsubscribe punsubscribe].include?(commands.first.first.to_s.downcase) &&
         commands.first.size == 1

        # Node is indeterminate. We do just a best-effort try here.
        @node.process_all(commands, &block)
      else
        node = assign_node(commands.first)
        try_send(node, :process, commands, &block)
      end
    end

    private

    def fetch_cluster_info!(option)
      node = Node.new(option.per_node_key)
      available_slots = SlotLoader.load(node)
      node_flags = NodeLoader.load_flags(node)
      option.update_node(available_slots.keys.map { |k| NodeKey.optionize(k) })
      [Node.new(option.per_node_key, node_flags, option.use_replica?),
       Slot.new(available_slots, node_flags, option.use_replica?)]
    ensure
      node&.each(&:disconnect)
    end

    def fetch_command_details(nodes)
      details = CommandLoader.load(nodes)
      Command.new(details)
    end

    def send_command(command, &block)
      cmd = command.first.to_s.downcase
      case cmd
      when 'acl', 'auth', 'bgrewriteaof', 'bgsave', 'quit', 'save'
        @node.call_all(command, &block).first
      when 'flushall', 'flushdb'
        @node.call_master(command, &block).first
      when 'wait'     then @node.call_master(command, &block).reduce(:+)
      when 'keys'     then @node.call_slave(command, &block).flatten.sort
      when 'dbsize'   then @node.call_slave(command, &block).reduce(:+)
      when 'scan'     then _scan(command, &block)
      when 'lastsave' then @node.call_all(command, &block).sort
      when 'role'     then @node.call_all(command, &block)
      when 'config'   then send_config_command(command, &block)
      when 'client'   then send_client_command(command, &block)
      when 'cluster'  then send_cluster_command(command, &block)
      when 'readonly', 'readwrite', 'shutdown'
        raise OrchestrationCommandNotSupported, cmd
      when 'memory'   then send_memory_command(command, &block)
      when 'script'   then send_script_command(command, &block)
      when 'pubsub'   then send_pubsub_command(command, &block)
      when 'discard', 'exec', 'multi', 'unwatch'
        raise AmbiguousNodeError, cmd
      else
        node = assign_node(command)
        try_send(node, :call, command, &block)
      end
    end

    def send_config_command(command, &block)
      case command[1].to_s.downcase
      when 'resetstat', 'rewrite', 'set'
        @node.call_all(command, &block).first
      else assign_node(command).call(command, &block)
      end
    end

    def send_memory_command(command, &block)
      case command[1].to_s.downcase
      when 'stats' then @node.call_all(command, &block)
      when 'purge' then @node.call_all(command, &block).first
      else assign_node(command).call(command, &block)
      end
    end

    def send_client_command(command, &block)
      case command[1].to_s.downcase
      when 'list' then @node.call_all(command, &block).flatten
      when 'pause', 'reply', 'setname'
        @node.call_all(command, &block).first
      else assign_node(command).call(command, &block)
      end
    end

    def send_cluster_command(command, &block)
      subcommand = command[1].to_s.downcase
      case subcommand
      when 'addslots', 'delslots', 'failover', 'forget', 'meet', 'replicate',
           'reset', 'set-config-epoch', 'setslot'
        raise OrchestrationCommandNotSupported, 'cluster', subcommand
      when 'saveconfig' then @node.call_all(command, &block).first
      else assign_node(command).call(command, &block)
      end
    end

    def send_script_command(command, &block)
      case command[1].to_s.downcase
      when 'debug', 'kill'
        @node.call_all(command, &block).first
      when 'flush', 'load'
        @node.call_master(command, &block).first
      else assign_node(command).call(command, &block)
      end
    end

    def send_pubsub_command(command, &block)
      case command[1].to_s.downcase
      when 'channels' then @node.call_all(command, &block).flatten.uniq.sort
      when 'numsub'
        @node.call_all(command, &block).reject(&:empty?).map { |e| Hash[*e] }
             .reduce({}) { |a, e| a.merge(e) { |_, v1, v2| v1 + v2 } }
      when 'numpat' then @node.call_all(command, &block).reduce(:+)
      else assign_node(command).call(command, &block)
      end
    end

    # @see https://redis.io/topics/cluster-spec#redirection-and-resharding
    #   Redirection and resharding
    def try_send(node, method_name, *args, retry_count: 3, &block)
      node.public_send(method_name, *args, &block)
    rescue CommandError => err
      if err.message.start_with?('MOVED')
        raise if retry_count <= 0

        node = assign_redirection_node(err.message)
        retry_count -= 1
        retry
      elsif err.message.start_with?('ASK')
        raise if retry_count <= 0

        node = assign_asking_node(err.message)
        node.call(%i[asking])
        retry_count -= 1
        retry
      else
        raise
      end
    rescue CannotConnectError
      update_cluster_info!
      raise
    end

    def _scan(command, &block)
      input_cursor = Integer(command[1])

      client_index = input_cursor % 256
      raw_cursor = input_cursor >> 8

      clients = @node.scale_reading_clients

      client = clients[client_index]
      return ['0', []] unless client

      command[1] = raw_cursor.to_s

      result_cursor, result_keys = client.call(command, &block)
      result_cursor = Integer(result_cursor)

      if result_cursor == 0
        client_index += 1
      end

      [((result_cursor << 8) + client_index).to_s, result_keys]
    end

    def assign_redirection_node(err_msg)
      _, slot, node_key = err_msg.split(' ')
      slot = slot.to_i
      @slot.put(slot, node_key)
      find_node(node_key)
    end

    def assign_asking_node(err_msg)
      _, _, node_key = err_msg.split(' ')
      find_node(node_key)
    end

    def assign_node(command)
      node_key = find_node_key(command)
      find_node(node_key)
    end

    def find_node_key(command, primary_only: false)
      key = @command.extract_first_key(command)
      return if key.empty?

      slot = KeySlotConverter.convert(key)
      return unless @slot.exists?(slot)

      if @command.should_send_to_master?(command) || primary_only
        @slot.find_node_key_of_master(slot)
      else
        @slot.find_node_key_of_slave(slot)
      end
    end

    def find_node(node_key)
      return @node.sample if node_key.nil?

      @node.find_by(node_key)
    rescue Node::ReloadNeeded
      update_cluster_info!(node_key)
      @node.find_by(node_key)
    end

    def update_cluster_info!(node_key = nil)
      unless node_key.nil?
        host, port = NodeKey.split(node_key)
        @option.add_node(host, port)
      end

      @node.map(&:disconnect)
      @node, @slot = fetch_cluster_info!(@option)
    end
  end
end
