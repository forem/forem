module Api
  module Admin
    class ApiError < StandardError
      attr_reader :error_code, :status

      def initialize(error_code, message, status: 400)
        @error_code = error_code
        @status = status
        super(message)
      end
    end
  end
end
