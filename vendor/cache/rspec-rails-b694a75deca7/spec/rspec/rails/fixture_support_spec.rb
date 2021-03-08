module RSpec::Rails
  RSpec.describe FixtureSupport do
    context "with use_transactional_fixtures set to false" do
      it "still supports fixture_path" do
        allow(RSpec.configuration).to receive(:use_transactional_fixtures) { false }
        group = RSpec::Core::ExampleGroup.describe do
          include FixtureSupport
        end

        expect(group).to respond_to(:fixture_path)
        expect(group).to respond_to(:fixture_path=)
      end
    end

    it "will allow #setup_fixture to run successfully", skip: Rails.version.to_f <= 6.0 do
      group = RSpec::Core::ExampleGroup.describe do
        include FixtureSupport

        self.use_transactional_tests = false
      end

      expect { group.new.setup_fixtures }.to_not raise_error
    end
  end
end
