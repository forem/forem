namespace :algoliasearch do

  desc "Reindex all models"
  task :reindex => :environment do
    AlgoliaSearch::Utilities.reindex_all_models
  end

  desc "Set settings to all indexes"
  task :set_all_settings => :environment do
    AlgoliaSearch::Utilities.set_settings_all_models
  end
  
  desc "Clear all indexes"
  task :clear_indexes => :environment do
    puts "clearing all indexes"
    AlgoliaSearch::Utilities.clear_all_indexes
  end

end
