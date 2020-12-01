module RSpec::Rails
  RSpec.describe RequestExampleGroup do
    it_behaves_like "an rspec-rails example group mixin", :request,
                    './spec/requests/', '.\\spec\\requests\\',
                    './spec/integration/', '.\\spec\\integration\\',
                    './spec/api/', '.\\spec\\api\\'
  end
end
