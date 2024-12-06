require 'algolia'
require 'test_helper'

class UserAgentTest
  describe 'define user agent' do
    def before_all
      @default = "Algolia for Ruby (#{Algolia::VERSION}), Ruby (#{RUBY_VERSION})"
    end

    def test_add_user_agents
      Algolia::UserAgent.add('Foo Bar', 'v1.0')
      Algolia::UserAgent.add('Front Web', '2.0')
      assert_equal(format('%<default>s; Foo Bar (v1.0); Front Web (2.0)', default: @default), Algolia::UserAgent.value)
    end
  end
end
