# frozen_string_literal: true

module KnapsackPro
  class TestFlatDistributor
    DIR_TYPES = [
      :feature,
      :integration,
      :e2e,
      :models,
      :views,
      :controllers,
    ]

    def initialize(test_files, node_total)
      @test_files = test_files
      @node_total = node_total
      set_default_nodes_hash
      set_grouped_test_files
    end

    def nodes
      group_test_files_by_directory
      generate_nodes
    end

    def test_files_for_node(node_index)
      nodes[node_index]
    end

    private

    attr_reader :test_files,
      :node_total,
      :nodes_hash,
      :grouped_test_files

    def set_default_nodes_hash
      @nodes_hash = {}
      node_total.times do |index|
        nodes_hash[index] = []
      end
    end

    def set_grouped_test_files
      @grouped_test_files = {}
      DIR_TYPES.each do |type|
        grouped_test_files[type] = []
      end
      grouped_test_files[:other] = []
    end

    def sorted_test_files
      test_files.sort_by { |t| t['path'] }
    end

    def group_test_files_by_directory
      sorted_test_files.each do |test_file|
        found = false
        DIR_TYPES.each do |type|
          if test_file['path'].match(/#{type}/)
            grouped_test_files[type] << test_file
            found = true
            break
          end
        end

        unless found
          grouped_test_files[:other] << test_file
        end
      end
    end

    def generate_nodes
      node_index = 0
      grouped_test_files.each do |_type, test_files|
        test_files.each do |test_file|
          nodes_hash[node_index] << test_file

          node_index += 1
          node_index %= node_total
        end
      end
      nodes_hash
    end
  end
end
