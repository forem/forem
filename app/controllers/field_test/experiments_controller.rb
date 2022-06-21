# This controller originally came from
# https://github.com/ankane/field_test/blob/master/app/controllers/field_test/experiments_controller.rb
module FieldTest
  class ExperimentsController < BaseController
    def index
      # More recently started experiments at the top
      @experiments = FieldTest::Experiment.all.sort_by(&:started_at).reverse
    end

    def show
      @experiment = FieldTest::Experiment.find(params[:id])
    rescue FieldTest::ExperimentNotFound
      raise ActionController::RoutingError, "Experiment not found"
    end
  end
end
