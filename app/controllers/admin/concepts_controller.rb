module Admin
  class ConceptsController < Admin::ApplicationController
    layout "admin"

    before_action :set_concept, only: %i[edit update destroy]

    def index
      @concepts = Concept.includes(:parent).order(:name)
    end

    def new
      @concept = Concept.new
    end

    def create
      @concept = Concept.new(concept_params)

      # Generate description and anchor embedding synchronously before saving
      Concepts::AnchorGenerator.new(@concept).call

      if @concept.save
        Concepts::BackfillClassifierWorker.perform_async(@concept.id)
        flash[:success] = "Concept created successfully. Backfill classification has been enqueued."
        redirect_to admin_concepts_path
      else
        flash.now[:error] = @concept.errors_as_sentence
        render :new
      end
    end

    def edit
    end

    def update
      @concept.assign_attributes(concept_params)

      # Re-generate embedding if name or description changes
      if @concept.name_changed? || @concept.description_changed?
        Concepts::AnchorGenerator.new(@concept).call
      end

      if @concept.save
        Concepts::BackfillClassifierWorker.perform_async(@concept.id)
        flash[:success] = "Concept updated successfully. Backfill classification has been enqueued."
        redirect_to admin_concepts_path
      else
        flash.now[:error] = @concept.errors_as_sentence
        render :edit
      end
    end

    def destroy
      if @concept.destroy
        flash[:success] = "Concept deleted successfully."
      else
        flash[:error] = @concept.errors_as_sentence
      end
      redirect_to admin_concepts_path
    end

    private

    def set_concept
      @concept = Concept.find(params[:id])
    end

    def concept_params
      params.require(:concept).permit(:name, :description, :parent_id)
    end
  end
end
