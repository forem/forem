class Internal::OrganizationsController < Internal::ApplicationController
  layout "internal"

  def index
    @organizations = Organization.order("name DESC").page(params[:page]).per(50)

    return if params[:search].blank?

    @organizations = @organizations.where(
      "name ILIKE ?",
      "%#{params[:search].strip}%",
    )
  end

  def show
    @organization = Organization.find(params[:id])
  end
end
