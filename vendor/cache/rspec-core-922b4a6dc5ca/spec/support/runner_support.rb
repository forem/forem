module RSpec::Core
  RSpec.shared_context "Runner support" do
    let(:out)    { StringIO.new         }
    let(:err)    { StringIO.new         }
    let(:config) { RSpec.configuration  }
    let(:world)  { RSpec.world          }

    def build_runner(*args)
      Runner.new(build_config_options(*args))
    end

    def build_config_options(*args)
      ConfigurationOptions.new(args)
    end
  end
end
