task after_assets_precompile: :environment do
  # Runs postcss/autoprefixer to ensure that our CSS works for all the browsers we support.
  system("pnpm postcss")
end

task install_pnpm: :environment do
  # print out HEROKU_SLUG_COMMIT to see if it's available
  puts "HEROKU_SLUG_COMMIT: #{ENV.fetch('HEROKU_SLUG_COMMIT', nil)}"
  puts "HEROKU_APP_NAME: #{ENV.fetch('HEROKU_APP_NAME', nil)}"
  system("pnpm --version > /dev/null 2>&1") || system("corepack enable pnpm")
end

Rake::Task["javascript:install"].enhance(["install_pnpm"])

Rake::Task["assets:precompile"].enhance do
  Rake::Task["after_assets_precompile"].execute
end
