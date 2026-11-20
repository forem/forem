module Admin
  class ConceptsController < Admin::ApplicationController
    layout "admin"

    before_action :set_concept_without_embedding, only: %i[show edit]
    before_action :set_concept, only: %i[update destroy trigger_lookback]

    CONCEPT_LIST_COLUMNS = %i[
      id name slug description parent_id similarity_threshold max_lookback_days score created_at updated_at
    ].freeze

    def index
      @concepts = Concept.select(*CONCEPT_LIST_COLUMNS).order(:name).to_a
      concepts_by_id = @concepts.index_by(&:id)
      @concepts.each do |concept|
        concept.association(:parent).target = concepts_by_id[concept.parent_id]
      end
      @membership_counts = ConceptMembership.group(:concept_id).count
    end

    def show
      if @concept.parent_id.present?
        ActiveRecord::Associations::Preloader.new(
          records: [@concept],
          associations: :parent,
          scope: Concept.select(:id, :name),
        ).call
      end

      @memberships = @concept.concept_memberships
        .order(created_at: :desc)
        .page(params[:page])
        .per(20)
      preload_membership_records(@memberships)

      @daily_metrics = @concept.concept_daily_metrics
        .order(date: :desc)
        .limit(30)
        .to_a
        .reverse

      @chart_dates = @daily_metrics.map { |m| m.date.strftime("%Y-%m-%d") }
      @chart_popularity = @daily_metrics.map(&:popularity_score)
      @chart_views = @daily_metrics.map(&:page_views)
      @chart_reactions = @daily_metrics.map(&:reactions_count)
    end

    def new
      @concept = Concept.new
    end

    def edit; end

    def create
      @concept = Concept.new(concept_params)

      # Generate description and anchor embedding synchronously before saving
      Concepts::AnchorGenerator.new(@concept).call

      if @concept.save
        Concepts::BackfillClassifierWorker.perform_async(@concept.id)
        flash[:success] = I18n.t("admin.concepts_controller.created")
        redirect_to admin_concepts_path
      else
        flash.now[:error] = @concept.errors_as_sentence
        render :new
      end
    end

    def update
      @concept.assign_attributes(concept_params)

      # Re-generate embedding if name or description changes
      if @concept.will_save_change_to_name? || @concept.will_save_change_to_description?
        Concepts::AnchorGenerator.new(@concept).call
      end

      if @concept.save
        Concepts::BackfillClassifierWorker.perform_async(@concept.id)
        flash[:success] = I18n.t("admin.concepts_controller.updated")
        redirect_to admin_concepts_path
      else
        flash.now[:error] = @concept.errors_as_sentence
        render :edit
      end
    end

    def destroy
      if @concept.destroy
        flash[:success] = I18n.t("admin.concepts_controller.deleted")
      else
        flash[:error] = I18n.t("admin.concepts_controller.failed_deletion")
      end
      redirect_to admin_concepts_path
    end

    def trigger_lookback
      days = params[:days].to_i

      if days <= 0 || days <= @concept.max_lookback_days
        flash[:error] = I18n.t("admin.concepts_controller.invalid_days")
      else
        Concepts::LookbackWorker.perform_async(@concept.id, days)
        flash[:success] = I18n.t("admin.concepts_controller.lookback_triggered", days: days)
      end

      redirect_to admin_concept_path(@concept)
    end

    private

    def set_concept
      @concept = Concept.find(params[:id])
    end

    def set_concept_without_embedding
      @concept = Concept.select(*CONCEPT_LIST_COLUMNS).find(params[:id])
    end

    def preload_membership_records(memberships)
      records_list = memberships.to_a
      return if records_list.empty?

      article_memberships = records_list.select { |m| m.record_type == "Article" }
      comment_memberships = records_list.select { |m| m.record_type == "Comment" }
      comments = preload_comment_memberships(comment_memberships)

      preload_article_records(article_memberships, comments)
      preload_other_memberships(records_list - article_memberships - comment_memberships)
      preload_record_users(article_memberships.filter_map(&:record) + comments)
    end

    def preload_comment_memberships(comment_memberships)
      return [] if comment_memberships.empty?

      ActiveRecord::Associations::Preloader.new(
        records: comment_memberships,
        associations: :record,
        scope: Comment.select(:id, :body_markdown, :user_id, :commentable_id, :commentable_type),
      ).call
      comment_memberships.filter_map(&:record)
    end

    def preload_article_records(article_memberships, comments)
      article_comments, other_comments = comments.partition { |c| c.commentable_type == "Article" }
      if other_comments.any?
        ActiveRecord::Associations::Preloader.new(records: other_comments, associations: :commentable).call
      end

      article_ids = (article_memberships.map(&:record_id) + article_comments.filter_map(&:commentable_id)).uniq
      return if article_ids.empty?

      articles_by_id = Article.select(:id, :title, :user_id).where(id: article_ids).index_by(&:id)
      article_memberships.each { |m| m.association(:record).target = articles_by_id[m.record_id] }
      article_comments.each { |c| c.association(:commentable).target = articles_by_id[c.commentable_id] }
    end

    def preload_other_memberships(other_memberships)
      return if other_memberships.empty?

      ActiveRecord::Associations::Preloader.new(records: other_memberships, associations: :record).call
    end

    def preload_record_users(user_records)
      user_ids = user_records.filter_map(&:user_id).uniq
      return if user_ids.empty?

      users_by_id = User.select(:id, :username).where(id: user_ids).index_by(&:id)
      user_records.each { |record| record.association(:user).target = users_by_id[record.user_id] }
    end

    def concept_params
      params.require(:concept).permit(:name, :description, :parent_id, :similarity_threshold, :score)
    end
  end
end
