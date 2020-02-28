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
      redirect_to internal_sponsorships_path
    else
      render action: :edit
    end
  end

  private

  def sponsorship_params
    params.require(:sponsorship).permit(%i[status expired_at])
  end
end
