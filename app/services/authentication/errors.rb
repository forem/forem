module Authentication
  module Errors
    class Error < StandardError
    end

    class ProviderNotFound < Error
    end
  end
end
