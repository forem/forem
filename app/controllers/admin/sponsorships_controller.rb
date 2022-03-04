module Admin
  class SponsorshipsController < Admin::ApplicationController
    layout "admin"

    def index
      @sponsorships = Sponsorship.includes(:organization, :user, :sponsorable)
        .order(created_at: :desc)
        .page(params[:page]).per(50)

      return if params[:status].blank?

      @sponsorships = @sponsorships.where(status: params[:status])
    end

    def new
      @sponsorship = Sponsorship.new
    end

    def edit
      @sponsorship = Sponsorship.find(params[:id])
    end

    def create
      @sponsorship = Sponsorship.new(sponsorship_params)

      if @sponsorship.save
        flash[:success] = "Sponsorship has been created!"
        redirect_to admin_sponsorships_path
      else
        flash[:danger] = @sponsorship.errors_as_sentence
        render :new
      end
    end

    def update
      @sponsorship = Sponsorship.find(params[:id])
      if @sponsorship.update(sponsorship_params)
        flash[:notice] = "Sponsorship was successfully updated"
        redirect_to admin_sponsorships_path
      else
        flash[:danger] = @sponsorship.errors_as_sentence
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
      redirect_to admin_sponsorships_path
    end

    private

    def sponsorship_params
      strong_params = params.fetch(:sponsorship, {})
        .permit(:status, :expires_at, :tagline, :url,
                :blurb_html, :featured_number,
                :instructions, :level, :user_id,
                :sponsorable_id, :sponsorable_type,
                :organization_id, :instructions_updated_at)

      if strong_params[:sponsorable_id].try(:empty?) || strong_params[:sponsorable_type].try(:empty?)
        # Clear sponsorable & sponsorable_type if they were left empty
        strong_params.delete("sponsorable_id")
        strong_params.delete("sponsorable_type")
      end
      strong_params
    end
  end
end
