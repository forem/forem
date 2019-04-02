module Api
  module V0
    include Pundit

    class AnalyticsController < ApplicationController
      def totals
        user = get_authenticated_user!

        data = if params[:organization_id]
                 org = Organization.find_by(id: params[:organization_id])
                 not_found unless org && belongs_to_org?(user, org)

                 AnalyticsService.new(organization: org).totals
               else
                 AnalyticsService.new(user: user).totals
               end
        render json: data.to_json
      end

      def historical
        raise ArgumentError if params[:start].blank?

        user = get_authenticated_user!

        data = if params[:organization_id]
                 org = Organization.find_by(id: params[:organization_id])
                 not_found unless org && belongs_to_org?(user, org)

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
                 not_found unless org && belongs_to_org?(user, org)

                 AnalyticsService.new(organization: org, start: DateTime.current - 1.day).stats_grouped_by_day
               else
                 AnalyticsService.new(user: user, start: DateTime.current - 1.day).stats_grouped_by_day
               end
        render json: data.to_json
      end

      private

      def get_authenticated_user!
        api_token = ApiSecret.find_by(secret: params[:api_token])
        not_found if api_token.blank?
        user = api_token.user

        not_found unless user.has_role? :pro
        user
      end

      def belongs_to_org?(user, org)
        user.organization_id == org.id
      end
    end
  end
end
