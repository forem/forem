class FavoritesController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  FAVORITABLE_TYPES = %w[Article Comment].freeze
  INVALID_USE_ERRORS = %i[not_found self_favorite ineligible].freeze

  def create
    favoritable = find_favoritable

    unless favoritable
      skip_authorization
      return render_favorite_error(:not_found)
    end

    authorize(favoritable, :create?, policy_class: FavoritePolicy)

    result = Favorites::Create.call(favoritable: favoritable, user: current_user)

    if result.success?
      head :ok
    else
      render_favorite_error(result.error)
    end
  end

  private

  def render_favorite_error(error)
    # Return generic error for invalid use cases
    code = INVALID_USE_ERRORS.include?(error) ? :cannot_favorite : error
    render json: {
      error: t("favorites_controller.create.#{code}"),
      code: code
    }, status: :unprocessable_entity
  end

  def find_favoritable
    type = params[:favoritable_type].to_s
    return unless FAVORITABLE_TYPES.include?(type)

    type.constantize.find_by(id: params[:favoritable_id])
  end
end
