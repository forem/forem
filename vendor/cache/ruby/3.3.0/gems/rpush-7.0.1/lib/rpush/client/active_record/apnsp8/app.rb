module Rpush
  module Client
    module ActiveRecord
      module Apnsp8
        class App < Rpush::Client::ActiveRecord::App
          include Rpush::Client::ActiveModel::Apnsp8::App
        end
      end
    end
  end
end
