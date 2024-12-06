module Rpush
  module Client
    module ActiveRecord
      module Wns
        class App < Rpush::Client::ActiveRecord::App
          include Rpush::Client::ActiveModel::Wns::App
        end
      end
    end
  end
end
