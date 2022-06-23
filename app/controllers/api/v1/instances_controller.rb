module Api
  module V1
    class InstancesController < ApiController
      include Api::InstancesController

      before_action :authenticate!
      before_action :set_no_cache_header
    end
  end
end
