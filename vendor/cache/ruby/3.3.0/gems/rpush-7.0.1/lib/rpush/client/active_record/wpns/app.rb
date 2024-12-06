module Rpush
  module Client
    module ActiveRecord
      module Wpns
        class App < Rpush::Client::ActiveRecord::App
          include Rpush::Client::ActiveModel::Wpns::App
        end
      end
    end
  end
end
