# frozen_string_literal: true

module KnapsackPro
  class AllocatorBuilder < BaseAllocatorBuilder
    def allocator
      KnapsackPro::Allocator.new(
        fast_and_slow_test_files_to_run: fast_and_slow_test_files_to_run,
        fallback_mode_test_files: fallback_mode_test_files,
        ci_node_total: env.ci_node_total,
        ci_node_index: env.ci_node_index,
        repository_adapter: repository_adapter,
      )
    end
  end
end
