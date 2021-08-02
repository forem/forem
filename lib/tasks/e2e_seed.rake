# Thanks to https://stackoverflow.com/questions/19872271/adding-a-custom-seed-file/31815032#31815032
SEED_DIR = Rails.root.join("spec/support/seeds/")

namespace :db do
  namespace :seed do
    desc "Seed data for e2e tests"
    task e2e: :environment do
      raise "Attempting to seed production environment, aborting!" if Rails.env.production?

      filename = SEED_DIR.join("seeds_e2e.rb")
      load(filename) if File.exist?(filename)
    end

    desc "Creator Onboarding seed data for e2e tests"
    task e2e_creator_onboarding: :environment do
      raise "Attempting to seed production environment, aborting!" if Rails.env.production?

      filename = SEED_DIR.join("creator_onboarding_seed_e2e.rb")
      load(filename) if File.exist?(filename)
    end
  end
end
