class Internal::OrganizationsController < Internal::ApplicationController
  layout "internal"

  def index
    @organizations = Organization.order("name DESC")

    return if params[:search].blank?

    @organizations = Organization.where(
      "name ILIKE ?",
      "%#{params[:search].strip}%",
    )
  end

  def show
    @organization = Organization.find(params[:id])
  end
end
