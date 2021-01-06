# Thanks to https://stackoverflow.com/questions/19872271/adding-a-custom-seed-file/31815032#31815032
SEED_DIR = Rails.root.join("spec/support/seeds/e2e/")

namespace :db do
  namespace :seed do
    desc "Seed data for e2e tests"
    task :e2e, [:file] => :environment do |_t, args|
      return if Rails.env.production?

      filename = SEED_DIR.join("#{args[:file]}.rb")
      load(filename) if File.exist?(filename)
    end
  end
end
