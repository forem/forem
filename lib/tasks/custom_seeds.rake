# Thanks to https://stackoverflow.com/questions/19872271/adding-a-custom-seed-file/31815032#31815032
SEED_DIR = Rails.root.join("spec/support/seeds/")

namespace :db do
  namespace :seed do
    desc "Seed data for e2e tests"
    task e2e: :environment do
      raise "Attempting to seed production environment, aborting!" if Rails.env.production?

      filename = SEED_DIR.join("seeds_e2e.rb")
      load(filename)
    end

    desc "Creator Onboarding seed data for e2e tests"
    task e2e_creator_onboarding: :environment do
      raise "Attempting to seed production environment, aborting!" if Rails.env.production?

      filename = SEED_DIR.join("creator_onboarding_seed_e2e.rb")
      load(filename)
    end

    desc "Preview environment seed data for Uffizzi"
    task staging: :environment do
      raise "Attempting to seed production environment, aborting!" if Rails.env.production?

      load(Rails.root.join("db/seeds_staging.rb"))
    end

    desc "Seed a bunch of random badges and achievements to users in development"
    task badges: :environment do
      raise "Attempting to seed production environment, aborting!" if Rails.env.production?

      puts "Creating random badges..."
      Faker::Number.unique.clear # Clear unique sequence so we don't run out of numbers
      created_badges = []
      45.times do |i|
        title = "#{Faker::Lorem.word.capitalize} #{Faker::Number.unique.number(digits: 3)}"
        badge = Badge.create!(
          title: title,
          description: Faker::Lorem.sentence,
          badge_image: Rails.root.join("app/assets/images/#{rand(1..40)}.png").open
        )
        created_badges << badge
      rescue => e
        puts "Skipping badge creation error: #{e.message}"
      end

      puts "Awarding badges randomly to users..."
      User.registered.without_role(:suspended).without_role(:spam).find_each do |user|
        # Award between 5 and 25 random badges to each user
        badges_to_award = created_badges.sample(rand(5..25))
        badges_to_award.each do |badge|
          unless BadgeAchievement.exists?(user_id: user.id, badge_id: badge.id)
            user.badge_achievements.create!(
              badge: badge,
              rewarding_context_message_markdown: Faker::Markdown.random
            )
          end
        end
      end

      puts "Seeding completed! Total badges: #{Badge.count}, Total achievements: #{BadgeAchievement.count}."
    end
  end
end
