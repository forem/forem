module Admin
  class ConsumerAppsController < Admin::ApplicationController
    layout "admin"

    def index
      @apps = ConsumerApps::FindOrCreateAllQuery.call
    end

    def new
      @app = ConsumerApp.new
    end

    def edit
      @app = ConsumerApp.find(params[:id])
      authorize @app
    end

    def create
      @app = ConsumerApp.new(consumer_app_params)
      authorize @app

      if @app.save
        flash[:success] = "#{@app.app_bundle} has been created!"
        redirect_to admin_consumer_apps_path
      else
        flash[:danger] = @app.errors_as_sentence
        render :new
      end
    end

    def update
      @app = ConsumerApp.find(params[:id])
      authorize @app

      if @app.update(consumer_app_params)
        flash[:success] = "#{@app.app_bundle} has been updated!"
        redirect_to admin_consumer_apps_path
      else
        flash[:danger] = @app.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @app = ConsumerApp.find(params[:id])
      authorize @app

      if @app.destroy
        flash[:success] = "#{@app.app_bundle} has been deleted!"
        redirect_to admin_consumer_apps_path
      else
        flash[:danger] = "Something went wrong with deleting #{@app.app_bundle}."
        render :edit
      end
    end

    private

    def consumer_app_params
      params.permit(:app_bundle, :platform, :auth_key)
    end
  end
end
