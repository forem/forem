module Admin
  # @note The ./config/routes/admin.rb file has a constraint around this controller
  #
  # @see https://github.com/orgs/forem/projects/46/views/1 project
  class SpacesController < Admin::ApplicationController
    layout "admin"

    # TODO: What kind of logging do we need?  Any?  Looking for guidance.  I can assume we want to
    # log changes to a space.
    #
    # after_action only: %i[update] { Audit::Logger.log(:moderator, current_user, params.dup) }

    # @note I'm instantiating the @space because in the index view I'm rendering a form that then
    # PUTs to the update action.
    def index
      authorize(Space)
      @space = Space.new
    end

    # @note The initial implementation of Spaces is simply exposing a means of toggling on or off a
    #       feature flag.  Further, the Space model is an ApplicationRecord model, but instead is
    #       the bare bones for a quick yet verbose implementation of the [Authorization System: use
    #       case 1-1](see https://github.com/orgs/forem/projects/46/views/1)
    def update
      # NOTE: We're not trying to find a space, we simply are treating this as a singleton type
      # resource.
      @space = Space.new(space_params)
      authorize(@space)

      # NOTE: As of <2022-03-16 Wed> we don't have validation on a space.
      @space.save

      respond_to do |wants|
        wants.html do
          redirect_to admin_spaces_path
        end
        wants.json do
          render json: @space, status: :ok
        end
      end
    end

    private

    def space_params
      params.fetch(:space).permit(:limit_post_creation_to_admins)
    end
  end
end
