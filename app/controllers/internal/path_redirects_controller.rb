module Internal
  class PathRedirectsController < Internal::ApplicationController
    layout "internal"

    before_action :set_path_redirect, only: %i[edit update destroy]

    after_action only: %i[update destroy create] do
      Audit::Logger.log(:internal, current_user, params.dup)
    end

    def new
      @path_redirect = PathRedirect.new
    end

    def create
      @path_redirect = PathRedirect.new(new_path_redirect_params)

      if @path_redirect.save
        flash[:success] = "Path Redirect created successfully!"
        redirect_to internal_path_redirects_path
      else
        flash[:danger] = @path_redirect.errors.full_messages.to_sentence
        render new_internal_path_redirect_path
      end
    end

    def index
      @q = PathRedirect.order(created_at: :desc).ransack(params[:q])
      @path_redirects = @q.result.page(params[:page] || 1).per(25)
    end

    def edit; end

    def update
      if @path_redirect.update(edit_path_redirect_params)
        flash[:success] = "Path Redirect updated successfully!"
        redirect_to edit_internal_path_redirect_path(@path_redirect)
      else
        flash[:danger] = @path_redirect.errors.full_messages.to_sentence
        render :edit
      end
    end

    def destroy
      if @path_redirect.destroy
        flash[:success] = "Path Redirect destroyed successfully!"
        redirect_to internal_path_redirects_path
      else # This should never be the case
        flash[:danger] = @path_redirect.errors.full_messages.to_sentence
        render :edit
      end
    end

    private

    def set_path_redirect
      @path_redirect = PathRedirect.find(params[:id])
    end

    def new_path_redirect_params
      params.require(:path_redirect).permit(:old_path, :new_path).merge(source: "admin")
    end

    def edit_path_redirect_params
      params.require(:path_redirect).permit(:new_path).merge(source: "admin")
    end
  end
end
