module Admin
  class EmailsController < Admin::ApplicationController
    layout "admin"

    before_action :ensure_no_customerio_cutover, only: %i[new edit create update]

    def index
      @emails = Email.includes(%i[audience_segment user_query event]).order("id DESC")

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
      load_form_dependencies
      @email = Email.new(event_id: params[:event_id], audience_segment_id: params[:audience_segment_id])
    end

    def edit
      load_form_dependencies
      @email = Email.find(params[:id])
    end

    def create
      @email = Email.new(email_params)
      if @email.save
        flash[:success] = if @email.status == "active"
                            I18n.t("admin.emails_controller.activated")
                          else
                            I18n.t("admin.emails_controller.drafted")
                          end
        redirect_to admin_email_path(@email.id)
      else
        load_form_dependencies
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
        load_form_dependencies
        flash[:danger] = @email.errors_as_sentence
        render :edit
      end
    end

    private

    def load_form_dependencies
      @audience_segments = AudienceSegment.including_user_counts.order(:name, :type_of, :id)
      @user_queries = UserQuery.active.order(:name)
      @events = Event.order(start_time: :desc)
    end

    def ensure_no_customerio_cutover
      return unless ForemInstance.customerio_email_cutover?

      flash[:danger] = I18n.t("admin.emails.customerio_cutover_notice")
      redirect_to admin_emails_path
    end

    def email_params
      params.require(:email).permit(
        :subject, :body, :audience_segment_id, :user_query_id, :event_id, :variables, :type_of, :drip_day, :status,
        :test_email_addresses, :override_footer_html, :custom_footer_html
      )
    end
  end
end
