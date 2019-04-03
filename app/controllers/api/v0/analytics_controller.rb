module Api
  module V0
    class AnalyticsController < ApiController
      rescue_from ArgumentError, with: :unprocessable_entity
      rescue_from UnauthorizedError, with: :not_authorized

      def totals
        user = get_authenticated_user!

        data = if params[:organization_id]
                 org = Organization.find_by(id: params[:organization_id])
                 raise UnauthorizedError unless org && belongs_to_org?(user, org)

                 AnalyticsService.new(organization: org).totals
               else
                 AnalyticsService.new(user: user).totals
               end
        render json: data.to_json
      end

      def historical
        raise ArgumentError, "Required 'start' parameter is missing" if params[:start].blank?
        raise ArgumentError, "Date parameters 'start' or 'end' must be in the format of 'yyyy-mm-dd'" unless valid_date_params?

        user = get_authenticated_user!

        data = if params[:organization_id]
                 org = Organization.find_by(id: params[:organization_id])
                 raise UnauthorizedError unless org && belongs_to_org?(user, org)

                 AnalyticsService.new(organization: org, start: params[:start], end: params[:end]).stats_grouped_by_day
               else
                 AnalyticsService.new(user: user, start: params[:start], end: params[:end]).stats_grouped_by_day
               end
        render json: data.to_json
      end

      def past_day
        user = get_authenticated_user!

        data = if params[:organization_id]
                 org = Organization.find_by(id: params[:organization_id])
                 raise UnauthorizedError unless org && belongs_to_org?(user, org)

                 AnalyticsService.new(organization: org, start: DateTime.current - 1.day).stats_grouped_by_day
               else
                 AnalyticsService.new(user: user, start: DateTime.current - 1.day).stats_grouped_by_day
               end
        render json: data.to_json
      end

      private

      def get_authenticated_user!
        api_token = ApiSecret.find_by(secret: params[:api_token])
        user = api_token&.user || current_user

        raise UnauthorizedError unless user.has_role? :pro

        user
      end

      def belongs_to_org?(user, org)
        user.organization_id == org.id
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
