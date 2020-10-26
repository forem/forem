task after_assets_precompile: :environment do
  # Runs postcss/autoprefixer to ensure that our CSS works for all the browsers we support.
  system("yarn postcss")
end

Rake::Task["assets:precompile"].enhance do
  Rake::Task["after_assets_precompile"].execute
end
