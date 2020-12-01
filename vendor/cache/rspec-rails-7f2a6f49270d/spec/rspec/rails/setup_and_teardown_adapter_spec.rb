RSpec.describe RSpec::Rails::SetupAndTeardownAdapter do
  describe ".setup" do
    it "registers before hooks in the order setup is received" do
      group = RSpec::Core::ExampleGroup.describe do
        include RSpec::Rails::SetupAndTeardownAdapter
        def self.foo; "foo"; end
        def self.bar; "bar"; end
      end
      expect(group).to receive(:before).ordered { |&block| expect(block.call).to eq "foo" }
      expect(group).to receive(:before).ordered { |&block| expect(block.call).to eq "bar" }
      expect(group).to receive(:before).ordered { |&block| expect(block.call).to eq "baz" }

      group.setup :foo
      group.setup :bar
      group.setup { "baz" }
    end

    it "registers prepend_before hooks for the Rails' setup methods" do
      group = RSpec::Core::ExampleGroup.describe do
        include RSpec::Rails::SetupAndTeardownAdapter
        def self.setup_fixtures; "setup fixtures"  end
        def self.setup_controller_request_and_response; "setup controller"  end
      end

      expect(group).to receive(:prepend_before) { |&block| expect(block.call).to eq "setup fixtures" }
      expect(group).to receive(:prepend_before) { |&block| expect(block.call).to eq "setup controller" }

      group.setup :setup_fixtures
      group.setup :setup_controller_request_and_response
    end

    it "registers teardown hooks in the order setup is received" do
      group = RSpec::Core::ExampleGroup.describe do
        include RSpec::Rails::SetupAndTeardownAdapter
        def self.foo; "foo"; end
        def self.bar; "bar"; end
      end
      expect(group).to receive(:after).ordered { |&block| expect(block.call).to eq "foo" }
      expect(group).to receive(:after).ordered { |&block| expect(block.call).to eq "bar" }
      expect(group).to receive(:after).ordered { |&block| expect(block.call).to eq "baz" }

      group.teardown :foo
      group.teardown :bar
      group.teardown { "baz" }
    end
  end
end
