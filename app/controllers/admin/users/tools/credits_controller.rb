module Admin
  module Users
    module Tools
      class CreditsController < Admin::ApplicationController
        layout false

        def show
          user = ::User.find(params[:user_id])

          render CreditsComponent.new(user: user), content_type: "text/html"
        end

        def create
          user = ::User.find(params[:user_id])

          respond_to do |format|
            format.js do
              ActiveRecord::Base.transaction do
                if credits_params[:organization_id].present?
                  Credits::Manage.call(
                    user,
                    add_org_credits: credits_params[:count],
                    organization_id: credits_params[:organization_id],
                  )
                else
                  Credits::Manage.call(user, add_credits: credits_params[:count])
                end

                create_note(user)
              end

              message = "Added #{credits_params[:count]} #{'credit'.pluralize(credits_params[:count].to_i)}!"
              render json: { result: message }, content_type: "application/json", status: :created
            rescue ActiveRecord::RecordInvalid => e
              render json: { error: e.message }, content_type: "application/json", status: :unprocessable_entity
            end
          end
        end

        def destroy
          user = ::User.find(params[:user_id])

          respond_to do |format|
            format.js do
              ActiveRecord::Base.transaction do
                if credits_params[:organization_id].present?
                  Credits::Manage.call(
                    user,
                    remove_org_credits: credits_params[:count],
                    organization_id: credits_params[:organization_id],
                  )
                else
                  Credits::Manage.call(user, remove_credits: credits_params[:count])
                end

                create_note(user)
              end

              message = "Removed #{credits_params[:count]} #{'credit'.pluralize(credits_params[:count].to_i)}!"
              render json: { result: message }, content_type: "application/json", status: :ok
            rescue ActiveRecord::RecordInvalid => e
              render json: { error: e.message }, content_type: "application/json", status: :unprocessable_entity
            end
          end
        end

        private

        def authorization_resource
          User
        end

        def credits_params
          params.require(:credits).permit(:count, :note, :organization_id)
        end

        def create_note(user)
          user.notes.create!(
            content: credits_params[:note],
            author: current_user,
            reason: :misc_note,
          )
        end
      end
    end
  end
end
