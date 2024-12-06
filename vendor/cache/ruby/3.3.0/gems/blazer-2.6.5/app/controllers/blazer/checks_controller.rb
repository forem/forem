module Blazer
  class ChecksController < BaseController
    before_action :set_check, only: [:edit, :update, :destroy, :run]

    def index
      state_order = [nil, "disabled", "error", "timed out", "failing", "passing"]
      @checks = Blazer::Check.joins(:query).includes(:query).order("blazer_queries.name, blazer_checks.id").to_a.sort_by { |q| state_order.index(q.state) || 99 }
      @checks.select! { |c| "#{c.query.name} #{c.emails}".downcase.include?(params[:q]) } if params[:q]
    end

    def new
      @check = Blazer::Check.new(query_id: params[:query_id])
    end

    def create
      @check = Blazer::Check.new(check_params)
      # use creator_id instead of creator
      # since we setup association without checking if column exists
      @check.creator = blazer_user if @check.respond_to?(:creator_id=) && blazer_user

      if @check.save
        redirect_to query_path(@check.query)
      else
        render_errors @check
      end
    end

    def update
      if @check.update(check_params)
        redirect_to query_path(@check.query)
      else
        render_errors @check
      end
    end

    def destroy
      @check.destroy
      redirect_to checks_path
    end

    def run
      @query = @check.query
      redirect_to query_path(@query)
    end

    private

      def check_params
        params.require(:check).permit(:query_id, :emails, :slack_channels, :invert, :check_type, :schedule)
      end

      def set_check
        @check = Blazer::Check.find(params[:id])
      end
  end
end
