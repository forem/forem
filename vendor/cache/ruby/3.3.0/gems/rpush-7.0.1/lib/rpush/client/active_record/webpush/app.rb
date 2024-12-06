module Rpush
  module Client
    module ActiveRecord
      module Webpush
        class App < Rpush::Client::ActiveRecord::App
          include Rpush::Client::ActiveModel::Webpush::App
        end
      end
    end
  end
end
