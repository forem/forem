module Admin
  class LinkedDomainsController < Admin::ApplicationController
    layout "admin"

    def index
      @linked_domains = LinkedDomain.order(created_at: :desc).page(params[:page]).per(20)
    end

    def edit
      @linked_domain = LinkedDomain.find(params[:id])
    end

    def update
      @linked_domain = LinkedDomain.find(params[:id])

      if @linked_domain.update(linked_domain_params)
        redirect_to admin_linked_domains_path, notice: "Linked domain was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def linked_domain_params
      params.require(:linked_domain).permit(:manual_setting)
    end
  end
end
