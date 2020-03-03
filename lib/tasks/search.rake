namespace :search do
  desc "set up Elasticsearch indexes"
  task setup: :environment do
    Search::Cluster.setup_indexes
  end

  desc "update Elasticsearch index mappings"
  task update_mappings: :environment do
    Search::Cluster.update_mappings
  end

  desc "tear down Elasticsearch indexes"
  task destroy: :environment do
    if Rails.env.production?
      puts "Will NOT destroy indexes in production"
      exit
    end

    Search::Cluster.delete_indexes
  end
end
