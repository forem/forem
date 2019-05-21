module Api
  module V0
    class AnalyticsController < ApiController
      rescue_from ArgumentError, with: :error_unprocessable_entity
      rescue_from UnauthorizedError, with: :error_unauthorized

      def totals
        user = get_authenticated_user!

        data = if params[:organization_id]
                 org = Organization.find_by(id: params[:organization_id])
                 raise UnauthorizedError unless org && org_member?(user, org)

                 AnalyticsService.new(org, article_id: params[:article_id]).totals
               else
                 AnalyticsService.new(user, article_id: params[:article_id]).totals
               end
        render json: data.to_json
      end

      def historical
        raise ArgumentError, "Required 'start' parameter is missing" if params[:start].blank?
        raise ArgumentError, "Date parameters 'start' or 'end' must be in the format of 'yyyy-mm-dd'" unless valid_date_params?

        user = get_authenticated_user!

        data = if params[:organization_id]
                 org = Organization.find_by(id: params[:organization_id])
                 raise UnauthorizedError unless org && org_member?(user, org)

                 AnalyticsService.new(org, start_date: params[:start], end_date: params[:end], article_id: params[:article_id]).stats_grouped_by_day
               else
                 AnalyticsService.new(user, start_date: params[:start], end_date: params[:end], article_id: params[:article_id]).stats_grouped_by_day
               end
        render json: data.to_json
      end

      def past_day
        user = get_authenticated_user!

        data = if params[:organization_id]
                 org = Organization.find_by(id: params[:organization_id])
                 raise UnauthorizedError unless org && org_member?(user, org)

                 AnalyticsService.new(org, start_date: 1.day.ago, article_id: params[:article_id]).stats_grouped_by_day
               else
                 AnalyticsService.new(user, start_date: 1.day.ago, article_id: params[:article_id]).stats_grouped_by_day
               end
        render json: data.to_json
      end

      private

      def get_authenticated_user!
        user = if request.headers["api-key"].blank?
                 current_user
               else
                 api_secret = ApiSecret.find_by(secret: request.headers["api-key"])
                 raise UnauthorizedError if api_secret.blank?

                 api_secret.user
               end

        raise UnauthorizedError unless user.present? && user.has_role?(:pro)

        user
      end

      def org_member?(user, org)
        OrganizationMembership.exists?(user: user, organization: org, type_of_user: %w[admin member])
      end

      def valid_date_params?
        date_regex = /\A\d{4}-\d{1,2}-\d{1,2}\Z/ # for example, 2019-03-22 or 2019-2-1
        if params[:end]
          (params[:start] =~ date_regex)&.zero? && (params[:end] =~ date_regex)&.zero?
        else
          (params[:start] =~ date_regex)&.zero?
        end
      end
    end
  end
end
