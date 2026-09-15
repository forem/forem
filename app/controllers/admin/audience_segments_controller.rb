module Admin
  class AudienceSegmentsController < Admin::ApplicationController
    layout "admin"

    before_action :set_audience_segment, only: %i[show edit update destroy add_users remove_user remove_users]
    before_action :disallow_modifying_system_segments, only: %i[edit update destroy add_users remove_user remove_users]

    def index
      @audience_segments = AudienceSegment.manual.including_user_counts.order(created_at: :desc)

      if params[:search].present?
        @audience_segments = @audience_segments.where("name ILIKE ?", "%#{params[:search].strip}%")
      end

      @audience_segments = @audience_segments.page(params[:page] || 1).per(20)
      @system_segments = AudienceSegment.not_manual.including_user_counts.order(:type_of)
    end

    def show
      @segmented_users_scope = @audience_segment.segmented_users.includes(user: :profile)

      if params[:search].present?
        search_term = "%#{params[:search].strip.downcase}%"
        @segmented_users_scope = @segmented_users_scope.joins(:user).where(
          "LOWER(users.username) LIKE :term OR LOWER(users.name) LIKE :term OR LOWER(users.email) LIKE :term",
          term: search_term,
        )
      end

      @segmented_users = @segmented_users_scope.order("segmented_users.created_at DESC")
        .page(params[:page] || 1)
        .per(25)
      @active_user_queries = UserQuery.active.order(:name)
      @linked_emails = @audience_segment.emails.order(id: :desc)
    end

    def new
      @audience_segment = AudienceSegment.new(type_of: :manual)
      @active_user_queries = UserQuery.active.order(:name)
    end

    def edit; end

    def create
      @audience_segment = AudienceSegment.new(audience_segment_params)
      @audience_segment.type_of = :manual

      if @audience_segment.save
        process_initial_users if params[:user_identifiers].present? || params[:user_query_id].present?
        flash[:success] = flash[:success].presence || I18n.t("admin.audience_segments_controller.created")
        redirect_to admin_audience_segment_path(@audience_segment)
      else
        @active_user_queries = UserQuery.active.order(:name)
        flash.now[:danger] = @audience_segment.errors_as_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @audience_segment.update(audience_segment_params)
        flash[:success] = I18n.t("admin.audience_segments_controller.updated")
        redirect_to admin_audience_segment_path(@audience_segment)
      else
        flash.now[:danger] = @audience_segment.errors_as_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @audience_segment.destroy
        flash[:success] = I18n.t("admin.audience_segments_controller.deleted")
        redirect_to admin_audience_segments_path
      else
        flash[:danger] = @audience_segment.errors_as_sentence.presence ||
          I18n.t("admin.audience_segments_controller.cannot_delete_in_use")
        redirect_to admin_audience_segment_path(@audience_segment)
      end
    end

    def add_users
      parse_result = SegmentedUsers::UserIdentifierParser.call(
        raw_input: params[:user_identifiers],
        user_query: params[:user_query_id],
      )

      if parse_result.valid_users.empty?
        flash[:danger] = I18n.t("admin.audience_segments_controller.no_valid_users_found")
      else
        existing_user_ids = @audience_segment.segmented_users
          .where(user_id: parse_result.valid_user_ids)
          .pluck(:user_id)
          .to_set
        users_to_add = parse_result.valid_user_ids.reject { |id| existing_user_ids.include?(id) }

        if users_to_add.any?
          SegmentedUsers::BulkUpsert.call(@audience_segment, user_ids: users_to_add)
        end

        messages = []
        messages << "#{users_to_add.size} user(s) successfully added to segment." if users_to_add.any?
        messages << "#{existing_user_ids.size} user(s) were already in this segment." if existing_user_ids.any?
        if parse_result.unresolved_identifiers.any?
          messages << "Could not resolve: #{parse_result.unresolved_identifiers.join(', ')}."
        end
        if parse_result.ineligible_users.any?
          ineligible_count = parse_result.ineligible_users.size
          messages << "Warning: #{ineligible_count} user(s) in this segment are not currently email eligible."
        end

        flash[:success] = messages.join(" ")
      end

      redirect_to admin_audience_segment_path(@audience_segment)
    end

    def remove_user
      user_id = params[:user_id]
      SegmentedUsers::BulkDelete.call(@audience_segment, user_ids: [user_id])
      flash[:success] = I18n.t("admin.audience_segments_controller.user_removed")
      redirect_to admin_audience_segment_path(@audience_segment)
    end

    def remove_users
      user_ids = params[:user_ids]
      if user_ids.present?
        SegmentedUsers::BulkDelete.call(@audience_segment, user_ids: user_ids)
        flash[:success] = I18n.t("admin.audience_segments_controller.users_removed", count: user_ids.size)
      else
        flash[:warning] = I18n.t("admin.audience_segments_controller.no_users_selected")
      end
      redirect_to admin_audience_segment_path(@audience_segment)
    end

    private

    def set_audience_segment
      @audience_segment = AudienceSegment.find(params[:id])
    end

    def disallow_modifying_system_segments
      return if @audience_segment.manual?

      flash[:danger] = I18n.t("admin.audience_segments_controller.system_segment_protected")
      redirect_to admin_audience_segments_path
    end

    def audience_segment_params
      params.require(:audience_segment).permit(:name)
    end

    def process_initial_users
      parse_result = SegmentedUsers::UserIdentifierParser.call(
        raw_input: params[:user_identifiers],
        user_query: params[:user_query_id],
      )

      return if parse_result.valid_users.empty?

      SegmentedUsers::BulkUpsert.call(@audience_segment, user_ids: parse_result.valid_user_ids)
      messages = ["Segment created with #{parse_result.valid_user_ids.size} user(s)."]
      if parse_result.unresolved_identifiers.any?
        messages << "Could not resolve: #{parse_result.unresolved_identifiers.join(', ')}."
      end
      flash[:success] = messages.join(" ")
    end
  end
end
