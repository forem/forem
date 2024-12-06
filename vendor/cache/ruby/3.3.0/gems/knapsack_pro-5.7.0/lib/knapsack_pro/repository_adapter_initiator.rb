# frozen_string_literal: true

module KnapsackPro
  class RepositoryAdapterInitiator
    def self.call
      case KnapsackPro::Config::Env.repository_adapter
      when 'git'
        KnapsackPro::RepositoryAdapters::GitAdapter.new
      else
        KnapsackPro::RepositoryAdapters::EnvAdapter.new
      end
    end
  end
end
