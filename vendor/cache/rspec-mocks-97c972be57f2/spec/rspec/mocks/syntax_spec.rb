module RSpec
  RSpec.describe Mocks do
    it "does not inadvertently define BasicObject on 1.8", :if => RUBY_VERSION.to_f < 1.9 do
      expect(defined?(::BasicObject)).to be nil
    end
  end
end
