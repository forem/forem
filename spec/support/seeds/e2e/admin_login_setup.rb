return if Rails.env.production?

require Rails.root.join("app/models/site_config")

# NOTE: when adding new data, please use the Seeder class to ensure the seed tasks
# stays idempotent.
require Rails.root.join("db/seeds/seeder")

seeder = Seeder.new

SiteConfig.waiting_on_first_user = false # The intial admin has been created
SiteConfig.public = false
puts "Seeding forem in starter mode to replicate new creator experience"

# NOTE: @citizen428 For the time being we want all current DEV profile fields.
# The CSV import is idempotent by itself, since it uses find_or_create_by.
seeder.create("Creating DEV profile fields") do
  dev_fields_csv = Rails.root.join("lib/data/dev_profile_fields.csv")
  ProfileFields::ImportFromCsv.call(dev_fields_csv)
end

seeder.create_if_doesnt_exist(User, "email", "admin@forem.local") do
  user = User.create!(
    name: "Admin McAdmin",
    email: "admin@forem.local",
    username: "Admin_McAdmin",
    summary: Faker::Lorem.paragraph_by_chars(number: 199, supplemental: false),
    profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    website_url: Faker::Internet.url,
    email_comment_notifications: false,
    email_follower_notifications: false,
    confirmed_at: Time.current,
    password: "password",
    password_confirmation: "password",
  )

  user.add_role(:super_admin)
  user.add_role(:single_resource_admin, Config)
end
