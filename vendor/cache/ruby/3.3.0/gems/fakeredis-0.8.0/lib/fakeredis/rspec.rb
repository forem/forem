# Require this either in your Gemfile or in RSpec's
# support scripts. Examples:
#
#   # Gemfile
#   group :test do
#     gem "rspec"
#     gem "fakeredis", :require => "fakeredis/rspec"
#   end
#
#   # spec/support/fakeredis.rb
#   require 'fakeredis/rspec'
#

require 'rspec/core'
require 'fakeredis'

RSpec.configure do |c|

  c.before do    
    Redis::Connection::Memory.reset_all_databases
    Redis::Connection::Memory.reset_all_channels
  end

end
