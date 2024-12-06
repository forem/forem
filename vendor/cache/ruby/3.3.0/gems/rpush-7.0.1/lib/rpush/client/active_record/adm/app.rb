module Rpush
  module Client
    module ActiveRecord
      module Adm
        class App < Rpush::Client::ActiveRecord::App
          include Rpush::Client::ActiveModel::Adm::App
        end
      end
    end
  end
end
