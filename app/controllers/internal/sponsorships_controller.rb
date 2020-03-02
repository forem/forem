class Internal::SponsorshipsController < Internal::ApplicationController
  layout "internal"

  def index
    @sponsorships = Sponsorship.includes(:organization, :user).order("created_at desc").page(params[:page]).per(50)
  end

  def edit
    @sponsorship = Sponsorship.find(params[:id])
  end

  def update
    @sponsorship = Sponsorship.find(params[:id])
    if @sponsorship.update(sponsorship_params)
      flash[:notice] = "Sponsorship was successfully updated"
      redirect_to internal_sponsorships_path
    else
      flash[:danger] = @sponsorship.errors.full_messages.join(", ")
      render action: :edit
    end
  end

  def destroy
    @sponsorship = Sponsorship.find(params[:id])
    if @sponsorship.destroy
      flash[:notice] = "Sponsorship was successfully destroyed"
    else
      flash[:danger] = "Sponsorship was not destroyed"
    end
    redirect_to internal_sponsorships_path
  end

  private

  def sponsorship_params
    params.require(:sponsorship).permit(%i[status expires_at tagline url blurb_html featured_number instructions instructions_updated_at])
  end
end
