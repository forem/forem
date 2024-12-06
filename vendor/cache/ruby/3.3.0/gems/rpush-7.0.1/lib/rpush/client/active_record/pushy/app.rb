module Rpush
  module Client
    module ActiveRecord
      module Pushy
        class App < Rpush::Client::ActiveRecord::App
          include Rpush::Client::ActiveModel::Pushy::App
        end
      end
    end
  end
end
