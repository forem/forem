require "rails_helper"

class SearchableModel
  include Searchable
  SEARCH_CLASS = Search::Tag

  def id
    1
  end
end

RSpec.describe Searchable do
  describe "#remove_from_elasticsearch" do
    it "enqueues job to delete model document from elasticsearch" do
      model = SearchableModel.new
      sidekiq_assert_enqueued_with(job: Search::RemoveFromElasticsearchIndexWorker, args: [SearchableModel::SEARCH_CLASS.to_s, model.id]) do
        model.remove_from_elasticsearch
      end
    end
  end
end
