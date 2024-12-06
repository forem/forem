# frozen_string_literal: true

module MemoryProfiler
  module TopN
    # Fast approach for determining the top_n entries in a Hash of Stat objects.
    # Returns results for both memory (memsize summed) and objects allocated (count) as a tuple.
    def top_n(max, metric_method)
      [
        top_n_memory(max, metric_method),
        top_n_objects(max, metric_method)
      ]
    end

    def top_n_memory(max, metric_method)
      metric_memsize = Hash.new(0)

      each_value do |value|
        metric = value.send(metric_method)
        metric_memsize[metric] += value.memsize
      end

      metric_memsize
        .to_a
        .sort_by! { |metric, memsize| [-memsize, metric] }
        .take(max)
        .map! { |metric, memsize| { data: metric, count: memsize } }
    end

    def top_n_objects(max, metric_method)
      metric_objects_count = Hash.new(0)

      each_value do |value|
        metric = value.send(metric_method)
        metric_objects_count[metric] += 1
      end

      metric_objects_count
        .to_a
        .sort_by! { |metric, count| [-count, metric] }
        .take(max)
        .map! { |metric, count| { data: metric, count: count } }
    end
  end
end
