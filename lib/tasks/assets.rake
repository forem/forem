namespace :assets do
  # Adapted from https://github.com/heroku/heroku-buildpack-ruby/issues/792
  desc "Remove 'node_modules' folder"
  task rm_node_modules: :environment do
    Rails.logger.info "Removing node_modules folder"
    FileUtils.remove_dir("node_modules", true)
  end

  # Adapted from https://github.com/sass/sassc-ruby/issues/200
  desc "Removes extra .o files from native extension builds"
  task clean_gem_artifacts: :environment do
    Bundler.bundle_path.glob("**/ext/**/*.o").each(&:delete)
  end
end

unless ENV["WEBPACKER_PRECOMPILE"] == "false"
  Rake::Task["assets:clean"].enhance do
    Rake::Task["assets:rm_node_modules"].invoke
    Rake::Task["assets:clean_gem_artifacts"].invoke
  end
end
