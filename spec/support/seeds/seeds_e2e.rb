return unless Rails.env.test? && ENV["E2E"].present?

# NOTE: when adding new data, please use the Seeder class to ensure the seed tasks
# stays idempotent.
require Rails.root.join("app/lib/seeder")

seeder = Seeder.new

##############################################################################
# Default development site config if different from production scenario

SiteConfig.public = true
SiteConfig.waiting_on_first_user = false

seeder.create_if_none(Organization) do
  3.times do
    Organization.create!(
      name: Faker::TvShows::SiliconValley.company,
      summary: Faker::Company.bs,
      remote_profile_image_url: logo = Faker::Company.logo,
      nav_image: logo,
      url: Faker::Internet.url,
      slug: "org#{rand(10_000)}",
      github_username: "org#{rand(10_000)}",
      twitter_username: "org#{rand(10_000)}",
      bg_color_hex: Faker::Color.hex_color,
      text_color_hex: Faker::Color.hex_color,
    )
  end
end

##############################################################################

# NOTE: @citizen428 For the time being we want all current DEV profile fields.
# The CSV import is idempotent by itself, since it uses find_or_create_by.
seeder.create("Creating DEV profile fields") do
  dev_fields_csv = Rails.root.join("lib/data/dev_profile_fields.csv")
  ProfileFields::ImportFromCsv.call(dev_fields_csv)
end

##############################################################################

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
    saw_onboarding: true,
    checked_code_of_conduct: true,
    checked_terms_and_conditions: true,
  )

  user.add_role(:super_admin)
  user.add_role(:single_resource_admin, Config)
end

##############################################################################

seeder.create_if_doesnt_exist(User, "email", "change-password-user@forem.com") do
  User.create!(
    name: "Change Password User",
    email: "change-password-user@forem.com",
    username: "changepassworduser",
    summary: Faker::Lorem.paragraph_by_chars(number: 199, supplemental: false),
    profile_image: File.open(Rails.root.join("app/assets/images/#{rand(1..40)}.png")),
    website_url: Faker::Internet.url,
    email_comment_notifications: false,
    email_follower_notifications: false,
    confirmed_at: Time.current,
    password: "password",
    password_confirmation: "password",
    saw_onboarding: true,
    checked_code_of_conduct: true,
    checked_terms_and_conditions: true,
  )
end

##############################################################################
