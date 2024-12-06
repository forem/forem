# frozen_string_literal: true

require_relative '../errors'

class Redis
  class Cluster
    # Keep details about Redis commands for Redis Cluster Client.
    # @see https://redis.io/commands/command
    class Command
      def initialize(details)
        @details = pick_details(details)
      end

      def extract_first_key(command)
        i = determine_first_key_position(command)
        return '' if i == 0

        key = command[i].to_s
        hash_tag = extract_hash_tag(key)
        hash_tag.empty? ? key : hash_tag
      end

      def should_send_to_master?(command)
        dig_details(command, :write)
      end

      def should_send_to_slave?(command)
        dig_details(command, :readonly)
      end

      private

      def pick_details(details)
        details.transform_values do |detail|
          {
            first_key_position: detail[:first],
            write: detail[:flags].include?('write'),
            readonly: detail[:flags].include?('readonly')
          }
        end
      end

      def dig_details(command, key)
        name = command.first.to_s
        return unless @details.key?(name)

        @details.fetch(name).fetch(key)
      end

      def determine_first_key_position(command)
        case command.first.to_s.downcase
        when 'eval', 'evalsha', 'migrate', 'zinterstore', 'zunionstore' then 3
        when 'object' then 2
        when 'memory'
          command[1].to_s.casecmp('usage').zero? ? 2 : 0
        when 'xread', 'xreadgroup'
          determine_optional_key_position(command, 'streams')
        else
          dig_details(command, :first_key_position).to_i
        end
      end

      def determine_optional_key_position(command, option_name)
        idx = command.map(&:to_s).map(&:downcase).index(option_name)
        idx.nil? ? 0 : idx + 1
      end

      # @see https://redis.io/topics/cluster-spec#keys-hash-tags Keys hash tags
      def extract_hash_tag(key)
        s = key.index('{')
        e = key.index('}', s.to_i + 1)

        return '' if s.nil? || e.nil?

        key[s + 1..e - 1]
      end
    end
  end
end
