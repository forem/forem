module Admin
  class BlockedEmailDomainsController < Admin::ApplicationController
    layout "admin"

    def index
      @blocked_email_domains = BlockedEmailDomain.order(:domain)
    end

    def new
      @blocked_email_domain = BlockedEmailDomain.new
    end

    def create
      @blocked_email_domain = BlockedEmailDomain.new(blocked_email_domain_params)

      if @blocked_email_domain.save
        redirect_to admin_blocked_email_domains_path, notice: "Blocked email domain was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @blocked_email_domain = BlockedEmailDomain.find(params[:id])
      @blocked_email_domain.destroy
      redirect_to admin_blocked_email_domains_path, notice: "Blocked email domain was successfully removed."
    end

    private

    def blocked_email_domain_params
      params.require(:blocked_email_domain).permit(:domain)
    end
  end
end
