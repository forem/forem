module Rpush
  module Reflectable
    def reflect(name, *args)
      Rpush.reflection_stack.each do |reflection_collection|
        begin
          reflection_collection.__dispatch(name, *args)
        rescue StandardError => e
          Rpush.logger.error(e)
        end
      end
    end
  end
end
