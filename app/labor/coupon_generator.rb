class CouponGenerator
  attr_accessor :id, :version

  def initialize(id, version)
    @id = id
    @version = version
  end

  def generate
    "#{version}_#{lambda_generated_code}"
  end

  private

  def lambda_generated_code
    response = FunctionCaller.new("blackbox-production-couponCode",
                                  { inputNumber: id, version: version }.to_json).call
    response.to_s(36)
  end
end
