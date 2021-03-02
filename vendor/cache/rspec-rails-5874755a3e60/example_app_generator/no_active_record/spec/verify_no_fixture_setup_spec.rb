# Pretend that ActiveRecord::Rails is defined and this doesn't blow up
# with `config.use_active_record = false`.
# Trick the other spec that checks that ActiveRecord is
# *not* defined by wrapping it in RSpec::Rails namespace
# so that it's reachable from RSpec::Rails::FixtureSupport.
# NOTE: this has to be defined before requiring `rails_helper`.
module RSpec
  module Rails
    module ActiveRecord
      module TestFixtures
      end
    end
  end
end

require 'rails_helper'

RSpec.describe 'Example App', :use_fixtures, type: :model do
  it "does not set up fixtures" do
    expect(defined?(fixtures)).not_to be
  end
end
