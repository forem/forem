module Gibbon
  class MailChimpError < StandardError
    attr_reader :title, :detail, :body, :raw_body, :status_code

    def initialize(message = "", params = {})
      @title       = params[:title]
      @detail      = params[:detail]
      @body        = params[:body]
      @raw_body    = params[:raw_body]
      @status_code = params[:status_code]

      super(message)
    end

    def to_s
      super + " " + instance_variables_to_s
    end

    private

    def instance_variables_to_s
      [:title, :detail, :body, :raw_body, :status_code].map do |attr|
        attr_value = send(attr)

        "@#{attr}=#{attr_value.inspect}"
      end.join(", ")
    end
  end
end
