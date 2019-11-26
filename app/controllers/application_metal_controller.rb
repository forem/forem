class ApplicationMetalController < ActionController::Metal
  # Any shared behavior across metal-oriented controllers can go here.
  include SessionCurrentUser
end
