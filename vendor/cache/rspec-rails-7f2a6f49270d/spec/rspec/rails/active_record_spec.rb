RSpec.describe "ActiveRecord support" do
  around do |ex|
    old_value = RSpec::Mocks.configuration.verify_partial_doubles?
    ex.run
    RSpec::Mocks.configuration.verify_partial_doubles = old_value
  end

  RSpec.shared_examples_for "stubbing ActiveRecord::Base" do
    it "allows you to stub `ActiveRecord::Base`" do
      allow(ActiveRecord::Base).to receive(:inspect).and_return("stubbed inspect")
      expect(ActiveRecord::Base.inspect).to eq "stubbed inspect"
    end
  end

  RSpec.shared_examples_for "stubbing abstract classes" do
    it "allows you to stub abstract classes" do
      klass = Class.new(ActiveRecord::Base) do
        self.abstract_class = true
      end
      allow(klass).to receive(:find).and_return("stubbed find")
      expect(klass.find(1)).to eq "stubbed find"
    end
  end

  context "with partial double verification enabled" do
    before do
      RSpec::Mocks.configuration.verify_partial_doubles = true
    end

    include_examples "stubbing ActiveRecord::Base"
    include_examples "stubbing abstract classes"
  end

  context "with partial double verification disabled" do
    before do
      RSpec::Mocks.configuration.verify_partial_doubles = false
    end

    include_examples "stubbing ActiveRecord::Base"
    include_examples "stubbing abstract classes"
  end
end
