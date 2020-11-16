module ResourceAdmin
  class ArticlesController < ResourceAdmin::ApplicationController
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

    def update
      if requested_resource.update(resource_params)
        Webhook::DispatchEvent.call("article_updated", requested_resource)
        redirect_to(
          [namespace, requested_resource],
          notice: translate_with_resource("update.success"),
        )
      else
        render :edit, locals: {
          page: Administrate::Page::Form.new(dashboard, requested_resource)
        }
      end
    end

    def destroy
      Articles::Destroyer.call(requested_resource)
      if requested_resource.destroyed?
        flash[:notice] = translate_with_resource("destroy.success")
      else
        flash[:error] = requested_resource.errors.full_messages.join("<br/>")
      end
      redirect_to action: :index
    end
  end
end
