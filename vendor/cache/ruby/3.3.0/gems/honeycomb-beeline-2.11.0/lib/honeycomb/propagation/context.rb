# frozen_string_literal: true

module Honeycomb
  module Propagation
    Context = Struct.new(:trace_id, :parent_id, :trace_fields, :dataset) do
      def to_array
        [trace_id, parent_id, trace_fields, dataset]
      end
    end
  end
end
