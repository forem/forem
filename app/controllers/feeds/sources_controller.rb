module Feeds
  class SourcesController < ApplicationController
    before_action :authenticate_user!
    after_action :verify_authorized

    def create
      @source = current_user.feed_sources.build(source_params)
      authorize @source

      if @source.save
        Feeds::ImportArticlesWorker::ForUser.perform_async(current_user.id, nil)
        flash[:notice] = I18n.t("feeds.sources.created")
        redirect_to "/dashboard/feed_imports"
      else
        flash[:error] = @source.errors_as_sentence
        redirect_to "/dashboard/feed_imports"
      end
    end

    def update
      @source = current_user.feed_sources.find(params[:id])
      authorize @source

      if @source.update(source_params)
        flash[:notice] = I18n.t("feeds.sources.updated")
      else
        flash[:error] = @source.errors_as_sentence
      end
      redirect_to "/dashboard/feed_imports"
    end

    def destroy
      @source = current_user.feed_sources.find(params[:id])
      authorize @source

      if @source.destroy
        flash[:notice] = I18n.t("feeds.sources.deleted")
      else
        flash[:error] = @source.errors_as_sentence
      end
      redirect_to "/dashboard/feed_imports"
    end

    private

    def source_params
      params.require(:feeds_source).permit(
        :feed_url, :name, :organization_id, :author_user_id, :mark_canonical, :referential_link
      )
    end
  end
end
