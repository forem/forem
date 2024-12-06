module FieldTest
  class ExperimentsController < BaseController
    def index
      @active_experiments, @completed_experiments = FieldTest::Experiment.all.sort_by(&:id).partition { |e| e.active? }
    end

    def show
      @experiment = FieldTest::Experiment.find(params[:id])

      @per_page = 200
      @page = [1, params[:page].to_i].max
      offset = (@page - 1) * @per_page
      @memberships = @experiment.memberships.order(created_at: :desc).limit(@per_page).offset(offset).to_a

      @events =
        if FieldTest.events_supported?
          @experiment.events.where(field_test_membership_id: @memberships.map(&:id)).group(:field_test_membership_id, :name).count
        else
          {}
        end
    rescue FieldTest::ExperimentNotFound
      raise ActionController::RoutingError, "Experiment not found"
    end
  end
end
