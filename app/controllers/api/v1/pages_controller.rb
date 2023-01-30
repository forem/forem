module Api
  module V1
    class PagesController < ApiController
      before_action :authenticate!, except: %i[show index]

      def index
        @pages = Page.all
        render json: @pages
      end

      def show
        @page = Page.find params[:id]
        render json: @page
      end
    end
  end
end
