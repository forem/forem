class AgentSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_agent_session, only: %i[show edit update destroy]
  after_action :verify_authorized

  def index
    authorize AgentSession
    @agent_sessions = current_user.agent_sessions.order(updated_at: :desc)
  end

  def new
    @agent_session = AgentSession.new
    authorize @agent_session
  end

  def create
    @agent_session = current_user.agent_sessions.new(title: create_params[:title])
    authorize @agent_session

    file = create_params[:session_file]
    tool_name = create_params[:tool_name]

    unless file
      render json: { error: "No file uploaded" }, status: :unprocessable_entity
      return
    end

    content = file.read
    if content.bytesize > AgentSession::MAX_RAW_DATA_SIZE
      render json: { error: "File too large (max 10MB)" }, status: :unprocessable_entity
      return
    end

    if tool_name == "auto"
      detected_tool = AgentSessionParsers::AutoDetect.detect_tool(content, filename: file.original_filename)
      @agent_session.parse_and_normalize!(content, detected_tool: detected_tool)
    else
      @agent_session.parse_and_normalize!(content)
    end

    if @agent_session.save
      respond_to do |format|
        format.html { redirect_to edit_agent_session_path(@agent_session), notice: "Session uploaded! Now curate which parts to include." }
        format.json do
          render json: {
            success: true,
            redirect_to: edit_agent_session_path(@agent_session),
            agent_session: session_json(@agent_session),
          }
        end
        format.any { redirect_to edit_agent_session_path(@agent_session) }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { error: @agent_session.errors.full_messages.join(", ") }, status: :unprocessable_entity }
        format.any { render :new, status: :unprocessable_entity }
      end
    end
  rescue StandardError => e
    render json: { error: "Failed to parse session: #{e.message}" }, status: :unprocessable_entity
  end

  def show
    authorize @agent_session
    @slice_name = params[:slice]
  end

  def edit
    authorize @agent_session
  end

  def update
    authorize @agent_session

    if update_params.key?(:curated_selections)
      @agent_session.curated_selections = update_params[:curated_selections]
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
        format.html { redirect_to edit_agent_session_path(@agent_session), notice: "Session updated." }
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
    redirect_to agent_sessions_path, notice: "Agent session deleted."
  end

  private

  def set_agent_session
    @agent_session = if params[:id]&.match?(/\A\d+\z/)
                       AgentSession.find(params[:id])
                     else
                       AgentSession.find_by!(slug: params[:id])
                     end
  end

  def create_params
    params.require(:agent_session).permit(:title, :tool_name, :session_file)
  end

  def update_params
    params.require(:agent_session).permit(:title, :published, curated_selections: [])
  end

  def parse_slices_param
    raw = params[:agent_session][:slices]
    slices = raw.is_a?(String) ? JSON.parse(raw) : raw.as_json
    slices.map do |s|
      {
        "name" => s["name"].to_s.strip.first(50),
        "indices" => Array(s["indices"]).map(&:to_i),
      }
    end
  rescue JSON::ParserError
    []
  end

  def session_json(session)
    {
      id: session.id,
      slug: session.slug,
      title: session.title,
      tool_name: session.tool_name,
      messages: session.messages,
      curated_selections: session.curated_selections,
      total_messages: session.total_messages,
      curated_count: session.curated_count,
      metadata: session.metadata,
      redactions: session.redactions,
      total_redactions: session.total_redactions,
      slices: session.slices,
    }
  end
end
