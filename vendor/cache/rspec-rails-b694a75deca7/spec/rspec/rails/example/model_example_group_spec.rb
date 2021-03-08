module RSpec::Rails
  RSpec.describe ModelExampleGroup do
    it_behaves_like "an rspec-rails example group mixin", :model,
                    './spec/models/', '.\\spec\\models\\'
  end
end
