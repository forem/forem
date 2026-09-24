class Api::V1::Admin::ConceptsController < Api::V1::Admin::BaseController
  before_action :set_concept, only: %i[show update destroy trigger_lookback]

  def index
    page = [params.fetch(:page, 1).to_i, 1].max
    per_page = [params.fetch(:per_page, 50).to_i, 100].min

    @concepts = Concept.select(:id, :name, :slug, :description, :parent_id, :similarity_threshold, :max_lookback_days, :created_at, :updated_at)
                       .order(:name)
                       .page(page)
                       .per(per_page)
    render json: @concepts
  end

  def show
    render json: @concept
  end

  def create
    @concept = Concept.new(concept_params)

    # Generate description and anchor embedding synchronously before saving
    Concepts::AnchorGenerator.new(@concept).call if @concept.name.present?

    if @concept.save
      Concepts::BackfillClassifierWorker.perform_async(@concept.id)
      render json: @concept, status: :created
    else
      render json: { errors: @concept.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @concept.assign_attributes(concept_params)

    # Re-generate embedding if name or description changes
    if @concept.will_save_change_to_name? || @concept.will_save_change_to_description?
      Concepts::AnchorGenerator.new(@concept).call if @concept.name.present?
    end

    if @concept.save
      Concepts::BackfillClassifierWorker.perform_async(@concept.id)
      render json: @concept
    else
      render json: { errors: @concept.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @concept.destroy
      head :no_content
    else
      render json: { errors: @concept.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def trigger_lookback
    days = params[:days].to_i

    if days <= 0 || days <= @concept.max_lookback_days
      render json: { error: I18n.t("admin.concepts_controller.invalid_days") }, status: :unprocessable_entity
    else
      Concepts::LookbackWorker.perform_async(@concept.id, days)
      render json: { message: I18n.t("admin.concepts_controller.lookback_triggered", days: days) }
    end
  end

  private

  def set_concept
    @concept = Concept.find(params[:id])
  end

  def concept_params
    params.require(:concept).permit(:name, :description, :parent_id, :similarity_threshold, :score)
  end
end
