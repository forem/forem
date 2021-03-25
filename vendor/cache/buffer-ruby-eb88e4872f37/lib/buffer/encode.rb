module Buffer
  class Encode
    class << self
      def encode(arg)
        raise_error_for_incorrect_input(arg)
        arg = arg[:schedules] if arg.respond_to?(:keys)
        arg.map.with_index do |item, index|
          process_schedule(item, index)
        end.join("&")
      end

      private

      def raise_error_for_incorrect_input(arg)
        unless arg.kind_of?(Hash) || arg.kind_of?(Array)
          raise ArgumentError, "Input must be/inherit from Hash or Array"
        end
      end

      def process_schedule(item, index)
        pairs_for(item).map do |key, value|
          "schedules[#{index}][#{key}][]=#{value}"
        end.join("&")
      end

      def pairs_for(item)
        uri = Addressable::URI.new
        uri.query_values = item
        uri.query.split("&").map {|p| p.split("=")}
      end
    end
  end
end
