module ActsAsForemStatsDriver
  extend ActiveSupport::Concern

  class_methods do
    def setup_driver
      define_method(:initialize) do
        @driver = yield
      end
    end
  end

  included do
    delegate :count, :increment, :time, :gauge, to: :@driver
  end
end
