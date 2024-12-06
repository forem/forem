# frozen_string_literal: true

require 'knapsack_pro'

namespace :knapsack_pro do
  task :encrypted_branch_names, [:branch] do |_, args|
    branch = args[:branch]

    branches =
      if branch
        [branch]
      else
        KnapsackPro::RepositoryAdapters::GitAdapter.new.branches
      end

    branches.each do |branch_name|
      encrypted_branch = KnapsackPro::Crypto::BranchEncryptor.new(branch_name).call

      puts "branch: #{branch_name}"
      puts "encrypted branch: #{encrypted_branch}"
      puts
    end
  end
end
