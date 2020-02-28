class Internal::SponsorshipsController < Internal::ApplicationController
  layout "internal"

  def index
    @sponsorships = Sponsorship.includes(:organization, :user).order("created_at desc").page(params[:page]).per(50)
  end

  def new
    @sponsorship = Sponsorship.new
  end

  def create
    @sponsorship = Sponsorship.new
  end
end
