module FakeRedis
  class ZSet < Hash

    def []=(key, val)
      super(key, _floatify(val))
    end

    def identical_scores?
      values.uniq.size == 1
    end

    # Increments the value of key by val
    def increment(key, val)
      self[key] += _floatify(val)
    end

    def select_by_score min, max
      min = _floatify(min, true)
      max = _floatify(max, false)
      select {|_,v| v >= min && v <= max }
    end

    private

    # Originally lifted from redis-rb
    def _floatify(str, increment = true)
      if (( inf = str.to_s.match(/^([+-])?inf/i) ))
        (inf[1] == "-" ? -1.0 : 1.0) / 0.0
      elsif (( number = str.to_s.match(/^\((\d+)/i) ))
        number[1].to_i + (increment ? 1 : -1)
      else
        Float str.to_s
      end
    rescue ArgumentError
      raise Redis::CommandError, "ERR value is not a valid float"
    end

  end
end
