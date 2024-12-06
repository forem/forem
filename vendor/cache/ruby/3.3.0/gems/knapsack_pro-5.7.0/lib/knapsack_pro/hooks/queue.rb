# frozen_string_literal: true

module KnapsackPro
  module Hooks
    class Queue
      class << self
        attr_reader :before_queue_store,
          :before_subset_queue_store,
          :after_subset_queue_store,
          :after_queue_store

        def reset_before_queue
          @before_queue_store = nil
        end

        def reset_before_subset_queue
          @before_subset_queue_store = nil
        end

        def reset_after_subset_queue
          @after_subset_queue_store = nil
        end

        def reset_after_queue
          @after_queue_store = nil
        end

        def before_queue(&block)
          @before_queue_store ||= []
          @before_queue_store << block
        end

        def before_subset_queue(&block)
          @before_subset_queue_store ||= []
          @before_subset_queue_store << block
        end

        def after_subset_queue(&block)
          @after_subset_queue_store ||= []
          @after_subset_queue_store << block
        end

        def after_queue(&block)
          @after_queue_store ||= []
          @after_queue_store << block
        end

        def call_before_queue
          return unless before_queue_store
          before_queue_store.each do |block|
            block.call(
              KnapsackPro::Config::Env.queue_id
            )
          end
        end

        def call_before_subset_queue
          return unless before_subset_queue_store
          before_subset_queue_store.each do |block|
            block.call(
              KnapsackPro::Config::Env.queue_id,
              KnapsackPro::Config::Env.subset_queue_id
            )
          end
        end

        def call_after_subset_queue
          return unless after_subset_queue_store
          after_subset_queue_store.each do |block|
            block.call(
              KnapsackPro::Config::Env.queue_id,
              KnapsackPro::Config::Env.subset_queue_id
            )
          end
        end

        def call_after_queue
          return unless after_queue_store
          after_queue_store.each do |block|
            block.call(
              KnapsackPro::Config::Env.queue_id
            )
          end
        end
      end
    end
  end
end
