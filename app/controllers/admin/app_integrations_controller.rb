module Admin
  class AppIntegrationsController < Admin::ApplicationController
    layout "admin"

    def index
      @apps = AppIntegrations::FetchAll.call
    end

    def new
      @app = AppIntegration.new
    end

    def edit
      @app = AppIntegration.find(params[:id])
      authorize @app
    end

    def create
      @app = AppIntegration.new(app_integration_params)
      @app.active = true
      authorize @app

      if @app.save
        flash[:success] = "#{@app.app_bundle} has been created!"
        redirect_to admin_app_integrations_path
      else
        flash[:danger] = @app.errors_as_sentence
        render :new
      end
    end

    def update
      @app = AppIntegration.find(params[:id])
      authorize @app

      if @app.update(app_integration_params)
        flash[:success] = "#{@app.app_bundle} has been updated!"
        redirect_to admin_app_integrations_path
      else
        flash[:danger] = @app.errors_as_sentence
        render :edit
      end
    end

    def destroy
      @app = AppIntegration.find(params[:id])
      authorize @app

      if @app.destroy
        flash[:success] = "#{@app.app_bundle} has been deleted!"
        redirect_to admin_app_integrations_path
      else
        flash[:danger] = "Something went wrong with deleting #{@app.app_bundle}."
        render :edit
      end
    end

    private

    def app_integration_params
      params.permit(:app_bundle, :platform, :auth_key)
    end
  end
end
