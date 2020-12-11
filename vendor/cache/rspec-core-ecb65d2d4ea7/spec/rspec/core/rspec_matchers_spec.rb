module RSpec::Matchers
  def __method_with_super
    super
  end

  module ModThatIncludesMatchers
    include RSpec::Matchers
  end

  RSpec.configure do |c|
    c.include RSpec::Matchers, :include_rspec_matchers => true
    c.include ModThatIncludesMatchers, :include_mod_that_includes_rspec_matchers => true
  end

  RSpec.describe self do
    shared_examples_for "a normal module with a method that supers" do
      it "raises the expected error (and not SystemStackError)" do
        expect { __method_with_super }.to raise_error(NoMethodError) # there is no __method_with_super in an ancestor
      end
    end

    it_behaves_like "a normal module with a method that supers"

    context "when RSpec::Matchers has been included in an example group" do
      include RSpec::Matchers
      it_behaves_like "a normal module with a method that supers"
    end

    context "when a module that includes RSpec::Matchers has been included in an example group" do
      include RSpec::Matchers::ModThatIncludesMatchers
      it_behaves_like "a normal module with a method that supers"
    end

    context "when RSpec::Matchers is included via configuration", :include_rspec_matchers => true do
      it_behaves_like "a normal module with a method that supers"
    end

    context "when RSpec::Matchers is included in a module that is included via configuration", :include_mod_that_includes_rspec_matchers => true do
      it_behaves_like "a normal module with a method that supers"
    end
  end
end

