class FunctionCaller
  attr_accessor :function_name, :payload
  def initialize(function_name, payload)
    @function_name = function_name
    @payload = payload
  end

  def call
    response = AwsLambda.invoke(function_name: function_name, payload: payload)
    JSON.parse(JSON.parse(response.payload.as_json[0])["body"])["message"]
  end
end
