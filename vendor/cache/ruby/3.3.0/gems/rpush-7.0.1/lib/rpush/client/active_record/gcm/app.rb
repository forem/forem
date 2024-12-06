module Rpush
  module Client
    module ActiveRecord
      module Gcm
        class App < Rpush::Client::ActiveRecord::App
          include Rpush::Client::ActiveModel::Gcm::App
        end
      end
    end
  end
end
