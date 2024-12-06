namespace :javascript do
  desc "Remove JavaScript builds"
  task :clobber do
    rm_rf Dir["app/assets/builds/**/[^.]*.{js,js.map}"], verbose: false
  end
end

if Rake::Task.task_defined?("assets:clobber")
  Rake::Task["assets:clobber"].enhance(["javascript:clobber"])
end
