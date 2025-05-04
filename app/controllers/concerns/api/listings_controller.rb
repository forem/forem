module Api
  module ListingsController
    extend ActiveSupport::Concern
    include Pundit::Authorization


    def index
      render json: []
    end

    def show
      render json: {}
    end

    def create
      head :ok
    end

    def update
      head :ok
    end

    def destroy
      head :ok
    end

    private
    attr_accessor :user
    alias current_user user
  end
end