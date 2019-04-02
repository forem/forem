module Api
  module V0
    include Pundit

    class AnalyticsController < ApplicationController
      after_action :verify_authorized

      def totals
        api_token = ApiSecret.find_by(secret: params[:api_token])
        user = api_token.user
        not_found if api_token.blank?

        authorize user, :pro_user?
        data = if params[:organization_id]
                 org = Organization.find_by(id: params[:organization_id])
                 head :unauthorized unless org && belongs_to_org?(user, org)

                 AnalyticsService.new(org: org).totals
               else
                 AnalyticsService.new(user: user).totals
               end
        render json: data.to_json
      end

      def historical
        raise ArgumentError if params[:start].blank?

        api_token = ApiSecret.find_by(secret: params[:api_token])
        user = api_token.user
        not_found if api_token.blank?

        authorize user, :pro_user?
        data = if params[:organization_id]
                 org = Organization.find_by(id: params[:organization_id])
                 not_found unless org && belongs_to_org?(user, org)

                 AnalyticsService.new(org: org, start: params[:start], end: params[:end]).stats_grouped_by_day
               else
                 AnalyticsService.new(user: user, start: params[:start], end: params[:end]).stats_grouped_by_day
               end
        render json: data.to_json
      end

      def past_day
        api_token = ApiSecret.find_by(secret: params[:api_token])
        user = api_token.user
        not_found if api_token.blank?

        authorize user, :pro_user?

        data = if params[:organization_id]
                 org = Organization.find_by(id: params[:organization_id])
                 not_found unless org && belongs_to_org?(user, org)

                 AnalyticsService.new(org: org, start: DateTime.current - 1.day).stats_grouped_by_day
               else
                 AnalyticsService.new(user: user, start: DateTime.current - 1.day).stats_grouped_by_day
               end
        render json: data.to_json
      end

      private

      def belongs_to_org?(user, org)
        user.organization == org
      end
    end
  end
end
