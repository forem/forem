require 'algolia'
require 'test_helper'

class AlgoliaConfigTest
  describe 'set an extra header' do
    def before_all
      @config = Algolia::BaseConfig.new(application_id: 'app_id', api_key: 'api_key')
    end

    def test_set_extra_header
      @config.set_extra_header('foo', 'bar')
      assert @config.headers['foo']
      assert_equal @config.headers['foo'], 'bar'
    end
  end
end
