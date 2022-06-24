class ApiConstraints
  def initialize(options)
    @version = options[:version]
    @default = options[:default]
  end

  def matches?(req)
    @default || req.headers["Accept"]&.include?("application/vnd.forem.api-v#{@version}+json")
  end
end
