class IndexClassifiedListingsToElasticsearch < ActiveRecord::DataMigration
  def up
    # Choose to do inline so development envs are ready immediately after
    # this is run
    ClassifiedListing.find_each(&:index_to_elasticsearch_inline)
  end
end
