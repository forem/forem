namespace :vcr do
  desc "Migrate cassettes from the VCR 1.x format to the VCR 2.x format."
  task :migrate_cassettes do
    dir = ENV.fetch('DIR') { raise "You must pass the cassette library directory as DIR=<directory>" }
    require 'vcr/cassette/migrator'
    VCR::Cassette::Migrator.new(dir).migrate!
  end
end

