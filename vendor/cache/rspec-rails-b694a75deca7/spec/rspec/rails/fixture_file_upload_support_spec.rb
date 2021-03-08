module RSpec::Rails
  RSpec.describe FixtureFileUploadSupport do
    context 'with fixture path set in config' do
      it 'resolves fixture file' do
        RSpec.configuration.fixture_path = File.dirname(__FILE__)
        expect_to_pass fixture_file_upload_resolved('fixture_file_upload_support_spec.rb')
      end

      it 'resolves supports `Pathname` objects' do
        RSpec.configuration.fixture_path = Pathname(File.dirname(__FILE__))
        expect_to_pass fixture_file_upload_resolved('fixture_file_upload_support_spec.rb')
      end
    end

    context 'with fixture path set in spec' do
      it 'resolves fixture file' do
        expect_to_pass fixture_file_upload_resolved('fixture_file_upload_support_spec.rb', File.dirname(__FILE__))
      end
    end

    context 'with fixture path not set' do
      it 'resolves fixture using relative path' do
        RSpec.configuration.fixture_path = nil
        expect_to_pass fixture_file_upload_resolved('spec/rspec/rails/fixture_file_upload_support_spec.rb')
      end
    end

    def expect_to_pass(group)
      result = group.run(failure_reporter)
      failure_reporter.exceptions.map { |e| raise e }
      expect(result).to be true
    end

    def fixture_file_upload_resolved(fixture_name, fixture_path = nil)
      RSpec::Core::ExampleGroup.describe do
        include RSpec::Rails::FixtureFileUploadSupport

        if ::Rails.version.to_f >= 6.1
          self.file_fixture_path = fixture_path
        else
          self.fixture_path = fixture_path
        end

        it 'supports fixture file upload' do
          file = fixture_file_upload(fixture_name)
          expect(file.read).to match(/describe FixtureFileUploadSupport/im)
        end
      end
    end
  end
end
