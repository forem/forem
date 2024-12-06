module Rpush
  module Client
    module Redis
      module Apnsp8
        class App < Rpush::Client::Redis::App
          include Rpush::Client::ActiveModel::Apnsp8::App
        end
      end
    end
  end
end
