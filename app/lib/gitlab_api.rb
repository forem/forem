class GitlabApi
  include HTTParty
  format :json
  base_uri "https://gitlab.com/api/v4/"
  logger ::Logger.new(STDOUT), :debug, :curl
  parser(proc { |body, _| JSON.parse(body, object_class: GitlabApiResponse) })

  attr_reader :project_name, :escaped_project

  def initialize(project)
    @project_name = project
    @escaped_project = escape(project)
  end

  def project
    path = "/projects/#{escaped_project}"
    get(path)
  end

  def issue(issue_id)
    path = "/projects/#{escaped_project}/issues/#{issue_id}"
    get(path)
  end

  def merge_request(merge_request_id)
    path = "/projects/#{escaped_project}/merge_requests/#{merge_request_id}"
    get(path)
  end

  def repository_file(file_path, ref)
    file_path = escape(file_path)
    path = "/projects/#{escaped_project}/repository/files/#{file_path}?ref=#{ref}"
    get(path)
  end

  def markdown(text)
    path = "/markdown"
    body = {
      text: text,
      project: project_name
    }
    post(path, body: body)
  end

  private

  def escape(path)
    CGI.escape(path)
  end

  %w[get post].each do |method|
    define_method method do |path, options = {}|
      params = options.dup

      validate_response self.class.send(method, path, params)
    end

    def validate_response(response)
      raise HTTParty::ResponseError, response unless response.success?

      response.parsed_response
    end
  end
end

class GitlabApiResponse < OpenStruct; end
