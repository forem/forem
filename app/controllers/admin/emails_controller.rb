module Admin
  class EmailsController < Admin::ApplicationController
    layout "admin"

    def index
      @emails = Email.includes([:audience_segment]).order("id DESC")

      # Apply filters
      @emails = @emails.where(type_of: params[:type_of]) if params[:type_of].present?
      @emails = @emails.where(status: params[:status]) if params[:status].present?
      if params[:search].present?
        @emails = @emails.where("subject ILIKE ? OR body ILIKE ?", "%#{params[:search]}%",
                                "%#{params[:search]}%")
      end

      @emails = @emails.page(params[:page] || 1).per(25)
    end

    def show
      @email = Email.find(params[:id])
    end

    def new
      @user_queries = UserQuery.active.order(:name)
      @email = Email.new
    end

    def edit
      @user_queries = UserQuery.active.order(:name)
      @email = Email.find(params[:id])
    end

    def create
      @email = Email.new(email_params)
      if @email.save
        flash[:success] =
          @email.status == "active" ? I18n.t("admin.emails_controller.activated") : I18n.t("admin.emails_controller.drafted")
        redirect_to admin_email_path(@email.id)
      else
        @user_queries = UserQuery.active.order(:name)
        flash[:danger] = @email.errors_as_sentence
        render :new
      end
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
        @user_queries = UserQuery.active.order(:name)
        flash[:danger] = @email.errors_as_sentence
        render :edit
      end
    end

    private

    def email_params
      params.require(:email).permit(:subject, :body, :user_query_id, :variables, :type_of, :drip_day, :status,
                                    :test_email_addresses)
    end
  end
end
