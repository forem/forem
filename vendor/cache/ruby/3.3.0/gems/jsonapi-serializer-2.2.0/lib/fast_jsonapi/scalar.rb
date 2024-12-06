module FastJsonapi
  class Scalar
    attr_reader :key, :method, :conditional_proc

    def initialize(key:, method:, options: {})
      @key = key
      @method = method
      @conditional_proc = options[:if]
    end

    def serialize(record, serialization_params, output_hash)
      if conditionally_allowed?(record, serialization_params)
        if method.is_a?(Proc)
          output_hash[key] = FastJsonapi.call_proc(method, record, serialization_params)
        else
          output_hash[key] = record.public_send(method)
        end
      end
    end

    def conditionally_allowed?(record, serialization_params)
      if conditional_proc.present?
        FastJsonapi.call_proc(conditional_proc, record, serialization_params)
      else
        true
      end
    end
  end
end
