module Authentication
  module Errors
    class Error < StandardError
    end

    class ProviderNotFound < Error
    end

    class ProviderNotEnabled < Error
    end
  end
end
