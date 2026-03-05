class AgentSessionsController < ApplicationController
  before_action :require_agent_sessions_enabled!
  before_action :authenticate_user!, except: %i[show]
  before_action :set_agent_session, only: %i[show edit update destroy raw_url]
  before_action :limit_uploads, only: %i[create presign]
  after_action :verify_authorized

  def index
    authorize AgentSession
    @agent_sessions = current_user.agent_sessions.order(updated_at: :desc)
  end

  def show
    return if performed? # already rendered by set_agent_session rescue

    authorize @agent_session
    @slice_name = params[:slice]
  rescue Pundit::NotAuthorizedError
    render_session_not_available
  end

  def new
    @agent_session = AgentSession.new
    authorize @agent_session
  end

  def edit
    authorize @agent_session
  end

  def create
    @agent_session = current_user.agent_sessions.new(title: create_params[:title])
    authorize @agent_session

    create_from_curated_data
  end

  def update
    authorize @agent_session

    if update_params.key?(:curated_data)
      update_curated_data
    end

    if update_params.key?(:title)
      @agent_session.title = update_params[:title]
    end

    if update_params.key?(:published)
      @agent_session.published = update_params[:published]
    end

    if params[:agent_session]&.key?(:slices)
      @agent_session.slices = parse_slices_param
    end

    if @agent_session.save
      respond_to do |format|
        format.html { redirect_to edit_agent_session_path(@agent_session), notice: "Session updated." } # rubocop:disable Rails/I18nLocaleTexts
        format.json { render json: { success: true, agent_session: session_json(@agent_session) } }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { error: @agent_session.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @agent_session
    @agent_session.destroy
    redirect_to agent_sessions_path, notice: "Agent session deleted." # rubocop:disable Rails/I18nLocaleTexts
  end

  def presign
    authorize AgentSession, :create?

    unless AgentSessions::S3Storage.enabled?
      render json: { error: "S3 storage is not configured" }, status: :service_unavailable
      return
    end

    s3_key = AgentSessions::S3Storage.generate_key(current_user.id)
    presigned_url = AgentSessions::S3Storage.presigned_put_url(s3_key)

    render json: { s3_key: s3_key, presigned_url: presigned_url }
  end

  def raw_url
    authorize @agent_session, :edit?

    unless @agent_session.raw_file_available? && AgentSessions::S3Storage.enabled?
      render json: { error: "No raw file available" }, status: :not_found
      return
    end

    url = AgentSessions::S3Storage.presigned_get_url(@agent_session.s3_key)
    render json: { raw_url: url }
  end

  private

  def require_agent_sessions_enabled!
    return if Settings::General.enable_agent_sessions

    respond_to do |format|
      format.html { render plain: "Agent Sessions are not enabled", status: :not_found }
      format.json { render json: { error: "Agent Sessions are not enabled" }, status: :not_found }
    end
  end

  def limit_uploads
    rate_limit!(:agent_session_creation)
  end

  def set_agent_session
    @agent_session = if params[:id]&.match?(/\A\d+\z/)
                       AgentSession.find(params[:id])
                     else
                       AgentSession.find_by!(slug: params[:id])
                     end
  rescue ActiveRecord::RecordNotFound
    render_session_not_available
  end

  def create_from_curated_data
    begin
      curated = parse_curated_data_param
    rescue JSON::ParserError => e
      render json: { error: "Invalid JSON in curated_data: #{e.message}" }, status: :unprocessable_entity
      return
    end
    tool_name = create_params[:tool_name]

    validation_errors = AgentSessionParsers::NormalizedDataValidator.validate(curated)
    if validation_errors.any?
      render json: { error: validation_errors.map(&:message).join(", ") }, status: :unprocessable_entity
      return
    end

    # Server-side secret scrubbing (defense in depth)
    result = AgentSessionParsers::SensitiveDataScrubber.scrub(curated)
    @agent_session.tool_name = tool_name.presence || curated.dig("metadata", "tool_name") || "claude_code"
    @agent_session.curated_data = result.scrubbed_data
    @agent_session.s3_key = create_params[:s3_key] if create_params[:s3_key].present?
    @agent_session.session_metadata = result.scrubbed_data.fetch("metadata", {}).merge(
      "redactions" => result.redactions.map { |r| { "name" => r.pattern_name, "count" => r.match_count } },
    )

    if params[:agent_session]&.key?(:slices)
      @agent_session.slices = parse_create_slices_param
    end

    save_and_respond_create
  end

  def save_and_respond_create
    if @agent_session.save
      rate_limiter.track_limit_by_action(:agent_session_creation)
      respond_to do |format|
        format.html do
          redirect_to edit_agent_session_path(@agent_session),
                      notice: "Session uploaded! Now curate which parts to include." # rubocop:disable Rails/I18nLocaleTexts
        end
        format.json do
          render json: {
            success: true,
            redirect_to: edit_agent_session_path(@agent_session),
            agent_session: session_json(@agent_session)
          }
        end
        format.any { redirect_to edit_agent_session_path(@agent_session) }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json do
          render json: { error: @agent_session.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
        format.any { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update_curated_data
    raw = update_params[:curated_data]
    curated = raw.is_a?(String) ? JSON.parse(raw, max_nesting: 50) : raw.to_unsafe_h
    result = AgentSessionParsers::SensitiveDataScrubber.scrub(curated)
    @agent_session.curated_data = result.scrubbed_data
    @agent_session.session_metadata = result.scrubbed_data.fetch("metadata", {}).merge(
      "redactions" => result.redactions.map { |r| { "name" => r.pattern_name, "count" => r.match_count } },
    )
  rescue JSON::ParserError
    # Ignore invalid JSON — validation will catch it
  end

  def parse_curated_data_param
    raw = create_params[:curated_data]
    raw.is_a?(String) ? JSON.parse(raw, max_nesting: 50) : raw.to_unsafe_h
  end

  def parse_create_slices_param
    raw = params[:agent_session][:slices]
    slices_data = raw.is_a?(String) ? JSON.parse(raw, max_nesting: 50) : raw.as_json
    slices_data.map do |s|
      {
        "name" => s["name"].to_s.strip.first(50),
        "indices" => Array(s["indices"]).map(&:to_i)
      }
    end
  rescue JSON::ParserError
    []
  end

  def create_params
    params.require(:agent_session).permit(:title, :tool_name, :curated_data, :s3_key)
  end

  def update_params
    params.require(:agent_session).permit(:title, :published, :curated_data)
  end

  def parse_slices_param
    raw = params[:agent_session][:slices]
    slices = raw.is_a?(String) ? JSON.parse(raw, max_nesting: 50) : raw.as_json
    slices.map do |s|
      {
        "name" => s["name"].to_s.strip.first(50),
        "indices" => Array(s["indices"]).map(&:to_i)
      }
    end
  rescue JSON::ParserError
    []
  end

  def render_session_not_available
    skip_authorization
    render "not_available", status: :not_found
  end

  def session_json(session)
    {
      id: session.id,
      slug: session.slug,
      title: session.title,
      tool_name: session.tool_name,
      messages: session.messages,
      total_messages: session.total_messages,
      curated_count: session.curated_count,
      metadata: session.metadata,
      redactions: session.redactions,
      total_redactions: session.total_redactions,
      slices: session.slices
    }
  end
end
