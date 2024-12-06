# frozen_string_literal: true

module KnapsackPro
  module Config
    class EnvGenerator
      class << self
        def set_queue_id
          if ENV['KNAPSACK_PRO_QUEUE_ID']
            raise 'Queue ID already generated.'
          else
            ENV['KNAPSACK_PRO_QUEUE_ID'] = "#{Time.now.to_i}_#{SecureRandom.uuid}"
          end
        end

        def set_subset_queue_id
          ENV['KNAPSACK_PRO_SUBSET_QUEUE_ID'] = SecureRandom.uuid
        end
      end
    end
  end
end
