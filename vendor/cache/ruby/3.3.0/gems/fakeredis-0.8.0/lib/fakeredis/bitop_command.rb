module FakeRedis
  module BitopCommand
    BIT_OPERATORS = {
      'or'  => :|,
      'and' => :&,
      'xor' => :'^',
      'not' => :~,
    }

    def bitop(operation, destkey, *keys)
      if result = apply(operator(operation), keys)
        set(destkey, result)
        result.length
      else
        0
      end
    rescue ArgumentError => _
      raise_argument_error('bitop')
    end

    private

    def operator(operation)
      BIT_OPERATORS[operation.to_s.downcase]
    end

    def apply(operator, keys)
      case operator
      when :~
        raise ArgumentError if keys.count != 1
        bitwise_not(keys.first)
      when :&, :|, :'^'
        raise ArgumentError if keys.empty?
        bitwise_operation(operator, keys)
      else
        raise ArgumentError
      end
    end

    def bitwise_not(key)
      if value = get(keys.first)
        value.bytes.map { |byte| ~ byte }.pack('c*')
      end
    end

    def bitwise_operation(operation, keys)
      apply_onto, *values = keys.map { |key| get(key) }.reject(&:nil?)
      values.reduce(apply_onto) do |memo, value|
        shorter, longer = [memo, value].sort_by(&:length).map(&:bytes).map(&:to_a)
        longer.each_with_index.map do |byte, index|
          byte.send(operation, shorter[index] || 0)
        end.pack('c*')
      end
    end
  end
end
