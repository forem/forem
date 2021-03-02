require 'support/aruba_support'

RSpec.describe 'Output stream' do
  include_context 'aruba support'
  before { setup_aruba }

  context 'when a formatter set in a configure block' do
    it 'writes to the right output stream' do
      write_file_formatted 'spec/example_spec.rb', <<-SPEC
        RSpec.configure do |c|
          c.formatter = :documentation
          c.output_stream = File.open('saved_output', 'w')
        end

        RSpec.describe 'something' do
          it 'succeeds' do
            true
          end
        end
      SPEC

      run_command ''
      expect(last_cmd_stdout).to be_empty
      cd '.' do
        expect(File.read('saved_output')).to include('1 example, 0 failures')
      end
    end

    it 'writes to the right output stream even when its a filename' do
      write_file_formatted 'spec/example_spec.rb', <<-SPEC
        RSpec.configure do |c|
          c.formatter = :documentation
          c.output_stream = 'saved_output'
        end

        RSpec.describe 'something' do
          it 'succeeds' do
            true
          end
        end
      SPEC

      run_command ''
      expect(last_cmd_stdout).to be_empty
      cd '.' do
        expect(File.read('saved_output')).to include('1 example, 0 failures')
      end
    end

    it 'writes to the right output stream even when its a filename' do
      write_file_formatted 'spec/example_spec.rb', <<-SPEC
        require 'pathname'
        RSpec.configure do |c|
          c.formatter = :documentation
          c.output_stream = Pathname.new('saved_output')
        end

        RSpec.describe 'something' do
          it 'succeeds' do
            true
          end
        end
      SPEC

      run_command ''
      expect(last_cmd_stdout).to be_empty
      cd '.' do
        expect(File.read('saved_output')).to include('1 example, 0 failures')
      end
    end
  end
end
