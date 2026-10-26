# Skip redundant `yarn install` and `yarn build` inside `assets:precompile` when
# `app/assets/builds` was already built by an earlier step (e.g. Heroku's Node
# buildpack or `Containerfile`), while keeping automatic builds in local/test runs
# or when only `app/assets/builds/.keep` is present.
builds_dir = Rails.root.join("app/assets/builds")
if Rake::Task.task_defined?("assets:precompile") &&
    ENV["RAILS_ENV"] == "production" &&
    builds_dir.glob("*.{js,css}").any?
  Rake::Task["assets:precompile"].prerequisites.delete("javascript:build")
end

task after_assets_precompile: :environment do
  # Runs postcss/autoprefixer to ensure that our CSS works for all the browsers we support.
  system("yarn postcss")
end

Rake::Task["assets:precompile"].enhance do
  Rake::Task["after_assets_precompile"].execute
end
