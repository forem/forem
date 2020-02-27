namespace :data do
  namespace :migrate do
    desc 'Apply pending data migrations asynchronously'
    task async: "data:init_migration" do
      # Ensure new code has been deployed before we run our data migrations
      DataUpdateWorker.perform_in(10.seconds)
    end
  end
end
