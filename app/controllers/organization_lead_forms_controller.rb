class OrganizationLeadFormsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_admin!
  before_action :set_lead_form, only: %i[edit update destroy toggle submissions]

  def index
    @lead_forms = @organization.lead_forms.order(created_at: :desc)
  end

  def create
    @lead_form = @organization.lead_forms.build(lead_form_params)
    if @lead_form.save
      flash[:settings_notice] = I18n.t("views.organization_settings.lead_forms.created")
      redirect_to organization_lead_forms_path(@organization.slug)
    else
      @lead_forms = @organization.lead_forms.order(created_at: :desc)
      render :index
    end
  end

  def edit
    @lead_forms = @organization.lead_forms.order(created_at: :desc)
    render :index
  end

  def update
    if @lead_form.update(lead_form_params)
      flash[:settings_notice] = I18n.t("views.organization_settings.lead_forms.updated")
      redirect_to organization_lead_forms_path(@organization.slug)
    else
      @lead_forms = @organization.lead_forms.order(created_at: :desc)
      render :index
    end
  end

  def destroy
    @lead_form.destroy
    flash[:settings_notice] = I18n.t("views.organization_settings.lead_forms.deleted")
    redirect_to organization_lead_forms_path(@organization.slug)
  end

  def toggle
    @lead_form.update!(active: !@lead_form.active?)
    flash[:settings_notice] = if @lead_form.active?
                                I18n.t("views.organization_settings.lead_forms.activated")
                              else
                                I18n.t("views.organization_settings.lead_forms.deactivated")
                              end
    redirect_to organization_lead_forms_path(@organization.slug)
  end

  def submissions
    respond_to do |format|
      format.csv do
        @submissions = @lead_form.lead_submissions.includes(:user).order(created_at: :desc)
        response.headers["Content-Type"] = "text/csv"
        response.headers["Content-Disposition"] = "attachment; filename=#{@lead_form.title.parameterize}-leads.csv"
        render template: "organization_lead_forms/submissions"
      end
    end
  end

  private

  def set_organization
    @organization = Organization.find_by(slug: params[:slug])
    not_found unless @organization
  end

  def authorize_admin!
    authorize @organization, :update?, policy_class: OrganizationPolicy
  end

  def set_lead_form
    @lead_form = @organization.lead_forms.find(params[:id])
  end

  def lead_form_params
    params.require(:organization_lead_form).permit(:title, :description, :button_text)
  end
end
