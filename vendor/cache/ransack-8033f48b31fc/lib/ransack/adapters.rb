module Ransack
  module Adapters

    def self.object_mapper
      @object_mapper ||= instantiate_object_mapper
    end

    def self.instantiate_object_mapper
      if defined?(::ActiveRecord::Base)
        ActiveRecordAdapter.new
      elsif defined?(::Mongoid)
        MongoidAdapter.new
      else
        raise "Unsupported adapter"
      end
    end

    class ActiveRecordAdapter
      def require_constants
        require 'ransack/adapters/active_record/ransack/constants'
      end

      def require_adapter
        require 'ransack/adapters/active_record/ransack/translate'
        require 'ransack/adapters/active_record'
      end

      def require_context
        require 'ransack/adapters/active_record/ransack/visitor'
      end

      def require_nodes
        require 'ransack/adapters/active_record/ransack/nodes/condition'
      end

      def require_search
        require 'ransack/adapters/active_record/ransack/context'
      end
    end

    class MongoidAdapter
      def require_constants
        require 'ransack/adapters/mongoid/ransack/constants'
      end

      def require_adapter
        require 'ransack/adapters/mongoid/ransack/translate'
        require 'ransack/adapters/mongoid'
      end

      def require_context
        require 'ransack/adapters/mongoid/ransack/visitor'
      end

      def require_nodes
        require 'ransack/adapters/mongoid/ransack/nodes/condition'
      end

      def require_search
        require 'ransack/adapters/mongoid/ransack/context'
      end
    end
  end
end
