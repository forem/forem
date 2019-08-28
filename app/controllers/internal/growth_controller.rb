class Internal::GrowthController < Internal::ApplicationController
  layout "internal"

  def index
    @variants = %w[0 1 2 3 4 5 6 7 8]
  end
end
