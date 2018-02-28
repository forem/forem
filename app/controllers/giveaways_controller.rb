class GiveawaysController < ApplicationController
  # GET /giveaways/new
  skip_before_action :ensure_signup_complete

  def new
    @user = current_user
    @errors = []
  end

  def edit
    @user = current_user
    @errors = []
  end

  # POST /giveaways
  # POST /giveaways.json
  # def create
  #   @user = User.new(giveaway_params)
  #
  #   respond_to do |format|
  #     if @user.save
  #       format.html { redirect_to @user, notice: 'Giveaway was successfully created.' }
  #       format.json { render :show, status: :created, location: @user }
  #     else
  #       format.html { render :new }
  #       format.json { render json: @user.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # PATCH/PUT /giveaways/1
  # PATCH/PUT /giveaways/1.json
  def update
    prevent_request_if_requested_twice
    @user = current_user
    @user.assign_attributes(user_params)
    @errors = []
    confirm_presence
    respond_to do |format|
      if @invalid_form
        render :edit
        return
      end
      @user.onboarding_package_requested_again = true if @user.onboarding_package_requested
      @user.onboarding_package_requested = true
      @user.onboarding_package_form_submmitted_at = Time.now.to_datetime
      @user.personal_data_updated_at = Time.now.to_datetime
      @user.shipping_validated_at = Time.now.to_datetime if user_params[:shipping_validated] == "1"
      if @user.save!
        format.html { redirect_to "/freestickers/edit" }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      accessible = [
                      :email,
                      :shipping_name,
                      :shipping_company,
                      :shipping_address,
                      :shipping_address_line_2,
                      :shipping_city,
                      :shipping_state,
                      :shipping_country,
                      :shipping_postal_code,
                      :shipping_validated,
                      :top_languages,
                      :experience_level,
                      :specialty,
                      :tabs_or_spaces,
                      :onboarding_package_requested,
                      :onboarding_package_form_submmitted_at,
                      :personal_data_updated_at,
                      :shirt_size,
                      :shirt_gender,
                    ]
      params.require(:user).permit(accessible)
    end

    def confirm_presence
      unless user_params[:shipping_name].present?
        @errors << "You need a shipping name"
        @invalid_form = true
      end
      unless user_params[:shipping_address].present?
        @errors << "You need a shipping address"
        @invalid_form = true
      end
      unless user_params[:shipping_city].present?
        @errors << "You need a shipping city"
        @invalid_form = true
      end
      unless user_params[:shipping_country].present?
        @errors << "You need a shipping country"
        @invalid_form = true
      end
      unless user_params[:top_languages].present?
        @errors << "You need to include your favorite languages. It's a spam filter."
        @invalid_form = true
      end

    end

    def prevent_request_if_requested_twice
      return if current_user.onboarding_package_requested_again
    end
end
