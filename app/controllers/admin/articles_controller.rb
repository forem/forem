module Admin
  class ArticlesController < Admin::ApplicationController
    def create
      resource = resource_class.new(resource_params)
      authorize_resource(resource)
      user = User.find(resource_params[:user_id])
      resource = Articles::Creator.call(user, resource_params)
      if resource.persisted?
        redirect_to(
          [namespace, resource],
          notice: translate_with_resource("create.success"),
        )
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, resource)
        }
      end
    end
  end
end
