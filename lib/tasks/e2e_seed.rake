# Thanks to https://stackoverflow.com/questions/19872271/adding-a-custom-seed-file/31815032#31815032
SEED_DIR = Rails.root.join("spec/support/seeds/")
seed_file = ENV["E2E_SEED_FILE"] || "seeds_e2e.rb"

ENV["E2E_SEED_FILE"]
namespace :db do
  namespace :seed do
    desc "Seed data for e2e tests"
    task e2e: :environment do
      raise "Attempting to seed production environment, aborting!" if Rails.env.production?

      filename = SEED_DIR.join(seed_file)
      if File.exist?(filename)
        load(filename)
      else
        raise "Unable to find the seed file #{filename}. If you are passing in a seed file from bin/e2e or bin/e2e-ci,\
ensure the file exists."
      end
    end
  end
end
