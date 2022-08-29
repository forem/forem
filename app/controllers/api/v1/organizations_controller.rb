module Api
  module V1
    class OrganizationsController < ApiController
      include Api::OrganizationsController

      before_action :find_organization, only: %i[users listings articles]
    end
  end
end
