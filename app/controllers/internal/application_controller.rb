class Internal::ApplicationController < ApplicationController
  include EnforceAdmin
  before_action :require_super_admin
end
