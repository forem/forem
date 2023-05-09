filename = Rails.root.join("db/seeds.rb")
ENV["SEEDS_MULTIPLIER"] = 3
load(filename)
