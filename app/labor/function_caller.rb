class FunctionCaller
  def initialize(function_name, payload, aws_lambda_client = AWS_LAMBDA)
    @function_name = function_name
    @payload = payload
    @aws_lambda_client = aws_lambda_client
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    response = aws_lambda_client.invoke(function_name: function_name, payload: payload)
    JSON.parse(JSON.parse(response.payload.as_json[0])["body"])["message"]
  end

  private

  attr_reader :function_name, :payload, :aws_lambda_client
end
