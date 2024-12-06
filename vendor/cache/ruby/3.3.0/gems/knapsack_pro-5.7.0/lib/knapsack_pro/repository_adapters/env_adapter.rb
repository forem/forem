# frozen_string_literal: true

module KnapsackPro
  module RepositoryAdapters
    class EnvAdapter < BaseAdapter
      def commit_hash
        KnapsackPro::Config::Env.commit_hash
      end

      def branch
        KnapsackPro::Config::Env.branch
      end
    end
  end
end
