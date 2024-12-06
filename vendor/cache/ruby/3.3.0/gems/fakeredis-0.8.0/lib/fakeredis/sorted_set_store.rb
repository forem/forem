module FakeRedis
  class SortedSetStore
    attr_accessor :data, :weights, :aggregate, :keys

    def initialize params, data
      self.data = data
      self.weights = params.weights
      self.aggregate = params.aggregate
      self.keys = params.keys
    end

    def hashes
      @hashes ||= keys.map do |src|
        case data[src]
        when ::Set
          # Every value has a score of 1
          Hash[data[src].map {|k,v| [k, 1]}]
        when Hash
          data[src]
        else
          {}
        end
      end
    end

    # Apply the weightings to the hashes
    def computed_values
      unless defined?(@computed_values) && @computed_values
        # Do nothing if all weights are 1, as n * 1 is n
        @computed_values = hashes if weights.all? {|weight| weight == 1 }
        # Otherwise, multiply the values in each hash by that hash's weighting
        @computed_values ||= hashes.each_with_index.map do |hash, index|
          weight = weights[index]
          Hash[hash.map {|k, v| [k, (v * weight)]}]
        end
      end
      @computed_values
    end

    def aggregate_sum out
      selected_keys.each do |key|
        out[key] = computed_values.inject(0) do |n, hash|
          n + (hash[key] || 0)
        end
      end
    end

    def aggregate_min out
      selected_keys.each do |key|
        out[key] = computed_values.map {|h| h[key] }.compact.min
      end
    end

    def aggregate_max out
      selected_keys.each do |key|
        out[key] = computed_values.map {|h| h[key] }.compact.max
      end
    end

    def selected_keys
      raise NotImplemented, "subclass needs to implement #selected_keys"
    end

    def call
      ZSet.new.tap {|out| send("aggregate_#{aggregate}", out) }
    end
  end

  class SortedSetIntersectStore < SortedSetStore
    def selected_keys
      @values ||= hashes.map(&:keys).reduce(:&)
    end
  end

  class SortedSetUnionStore < SortedSetStore
    def selected_keys
      @values ||= hashes.map(&:keys).flatten.uniq
    end
  end
end
