module Api
  module FeatureFlagsController
    extend ActiveSupport::Concern

    def create
      FeatureFlag.enable(params[:flag])
      head :ok
    end

    def show
      flag = params[:flag]
      render json: { flag => FeatureFlag.enabled?(flag) }
    end

    def destroy
      FeatureFlag.disable(params[:flag])
      head :ok
    end
  end
end
