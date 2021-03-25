module Buffer
  module Error
    ConfigFileMissing = Class.new(StandardError)
    InvalidIdLength = Class.new(ArgumentError)
    InvalidIdContent = Class.new(ArgumentError)
    MissingStatus = Class.new(ArgumentError)
    APIError = Class.new(StandardError)
    UnauthorizedRequest = Class.new(StandardError)
  end
end
