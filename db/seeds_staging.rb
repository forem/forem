filename = Rails.root.join("db/seeds.rb")
load(filename) if File.exist?(filename)
