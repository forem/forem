# Thanks to https://stackoverflow.com/questions/19872271/adding-a-custom-seed-file/31815032#31815032
namespace :db do
  namespace :seed do
    Dir[Rails.root.join("db/seeds/*.rb")].each do |filename|
      task_name = File.basename(filename, ".rb")
      desc "Seed #{task_name}, based on the file with the same name in `db/seeds/*.rb`"
      task task_name.to_sym => :environment do
        load(filename) if File.exist?(filename)
      end
    end
  end
end
