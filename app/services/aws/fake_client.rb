# Fake Aws client is used in non-production environments to prevent actual calls to AWS lambda
module Aws
  class FakeClient
    def initialize; end

    def invoke(_function_name:, _payload:)
      OpenStruct.new(payload: [{ body: { message: 0 }.to_json }.to_json])
    end
  end
end
