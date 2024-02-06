task after_assets_precompile: :environment do
  # Runs postcss/autoprefixer to ensure that our CSS works for all the browsers we support.
  system("yarn postcss")
end

task install_pnpm: :environment do
  system("pnpm --version > /dev/null 2>&1") || system("corepack enable pnpm")
end

if ENV["HEROKU_APP_NAME"]
  Rake::Task["javascript:install"].enhance(["install_pnpm"])
end

Rake::Task["assets:precompile"].enhance do
  Rake::Task["after_assets_precompile"].execute
end
