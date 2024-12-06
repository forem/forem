# frozen_string_literal: true

module KnapsackPro
  module RepositoryAdapters
    class BaseAdapter
      def commit_hash
        raise NotImplementedError
      end

      def branch
        raise NotImplementedError
      end

      def branches
        raise NotImplementedError
      end
    end
  end
end
