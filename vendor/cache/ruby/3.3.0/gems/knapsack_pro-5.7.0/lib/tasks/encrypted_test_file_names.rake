# frozen_string_literal: true

require 'knapsack_pro'

namespace :knapsack_pro do
  task :encrypted_test_file_names, [:adapter] do |_, args|
    adapter = args[:adapter]

    adapter_class = case adapter
                    when 'rspec'
                      KnapsackPro::Adapters::RSpecAdapter
                    when 'minitest'
                      KnapsackPro::Adapters::MinitestAdapter
                    when 'test_unit'
                      KnapsackPro::Adapters::TestUnitAdapter
                    when 'cucumber'
                      KnapsackPro::Adapters::CucumberAdapter
                    when 'spinach'
                      KnapsackPro::Adapters::SpinachAdapter
                    else
                      raise('Provide adapter name like rspec, minitest, test_unit, cucumber, spinach')
                    end

    test_file_pattern = KnapsackPro::TestFilePattern.call(adapter_class)
    test_files = KnapsackPro::TestFileFinder.call(test_file_pattern)

    test_file_names = []
    test_files.each do |t|
      test_file_names << {
        'path' => t['path'],
        'decrypted_path' => t['path'],
      }
    end

    encrypted_test_files = KnapsackPro::Crypto::Encryptor.new(test_file_names).call

    encrypted_test_files.each do |t|
      puts "path: #{t['decrypted_path']}"
      puts "encrypted path: #{t['path']}"
      puts
    end
  end
end
