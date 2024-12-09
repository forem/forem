module Admin
  class EmailsController < Admin::ApplicationController
    layout "admin"

    def index
      @emails = Email.page(params[:page] || 1).includes([:audience_segment]).order("id DESC").per(25)
    end

    def new
      @audience_segments = AudienceSegment.all
      @email = Email.new
    end

    def show
      @email = Email.find(params[:id])
    end

    def create
      @email = Email.new(email_params)
      if @email.save
        flash[:success] = @email.status == "active" ? I18n.t("admin.emails_controller.activated") :  I18n.t("admin.emails_controller.drafted")
        redirect_to admin_email_path(@email.id)
      else
        @audience_segments = AudienceSegment.all
        flash[:danger] = @email.errors_as_sentence
        render :new
      end
    end

    def edit
      @audience_segments = AudienceSegment.all
      @email = Email.find(params[:id])
    end

    def update
      @email = Email.find(params[:id])
      test_email_string = email_params[:test_email_addresses]
      if test_email_string.present?
        @email.deliver_to_test_emails(test_email_string)
        flash[:success] = "Test email delivering to #{test_email_string}"
        redirect_to admin_email_path(@email.id)
      elsif @email.update(email_params)
        flash[:success] = I18n.t("admin.emails_controller.updated")
        redirect_to admin_email_path(@email.id)
      else
        @audience_segments = AudienceSegment.all
        flash[:danger] = @email.errors_as_sentence
        render :edit
      end
    end

    private

    def email_params
      params.require(:email).permit(:subject, :body, :audience_segment_id, :type_of, :drip_day, :status, :test_email_addresses)
    end
  end
end
