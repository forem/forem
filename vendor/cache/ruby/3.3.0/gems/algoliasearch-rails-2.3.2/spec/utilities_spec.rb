require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

AlgoliaSearch.configuration = { :application_id => ENV['ALGOLIA_APPLICATION_ID'], :api_key => ENV['ALGOLIA_API_KEY'] }

describe AlgoliaSearch::Utilities do

  before(:each) do
    @included_in = AlgoliaSearch.instance_variable_get :@included_in
    AlgoliaSearch.instance_variable_set :@included_in, []

    class Dummy
      include AlgoliaSearch

      def self.model_name
        "Dummy"
      end

      algoliasearch
    end
  end

  after(:each) do
    AlgoliaSearch.instance_variable_set :@included_in, @included_in
  end

  it "should get the models where AlgoliaSearch module was included" do
    (AlgoliaSearch::Utilities.get_model_classes - [Dummy]).should == []
  end

end
