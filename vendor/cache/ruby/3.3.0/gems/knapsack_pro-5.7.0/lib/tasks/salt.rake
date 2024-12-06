# frozen_string_literal: true

namespace :knapsack_pro do
  task :salt, [:size] do |_, args|
    default_size = 32
    size = (args[:size] || default_size).to_i

    if size >= default_size
      salt = SecureRandom.hex(size)
      puts 'Set environment variable on your CI server:'
      puts "KNAPSACK_PRO_SALT=#{salt}"
      puts
      puts "If you need longer salt you can provide the size:"
      puts "$ bundle exec rake knapsack_pro:salt[32]"
      puts "Default size 32 generates 64 chars."
    else
      puts "Salt must have at least 64 chars! You provided size #{size} which generates #{size*2} chars."
    end
  end
end
