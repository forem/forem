require 'rspec/core/project_initializer'

module RSpec::Core
  RSpec.describe ProjectInitializer, :isolated_directory => true do

    describe "#run" do
      context "with no args" do
        subject(:command_line_config) { ProjectInitializer.new(:report_stream => output) }

        let(:output) { StringIO.new }

        context "with no .rspec file" do
          it "says it's creating .rspec " do
            expect{ command_line_config.run }.to change{
              output.rewind
              output.read
            }.to(include 'create   .rspec')
          end

          it "generates a .rspec" do
            command_line_config.run
            expect(File.read('.rspec')).to match(/--require spec_helper/m)
          end
        end

        context "with a .rspec file" do
          it "says .rspec exists" do
            FileUtils.touch('.rspec')
            expect{ command_line_config.run }.to change{
              output.rewind
              output.read
            }.to(include 'exist   .rspec')
          end

          it "doesn't create a new one" do
            File.open('.rspec', 'w') {|f| f << '--not-a-real-flag'}
            command_line_config.run
            expect(File.read('.rspec')).to eq('--not-a-real-flag')
          end
        end

        context "with no spec/spec_helper.rb file" do
          it "says it's creating spec/spec_helper.rb " do
            expect{ command_line_config.run }.to change{
              output.rewind
              output.read
            }.to(include 'create   spec/spec_helper.rb')
          end

          it "generates a spec/spec_helper.rb" do
            command_line_config.run
            expect(File.read('spec/spec_helper.rb')).to match(/RSpec\.configure do \|config\|/m)
          end
        end

        context "with a spec/spec_helper.rb file" do
          before { FileUtils.mkdir('spec') }

          it "says spec/spec_helper.rb exists" do
            FileUtils.touch('spec/spec_helper.rb')
            expect{ command_line_config.run }.to change{
              output.rewind
              output.read
            }.to(include 'exist   spec/spec_helper.rb')
          end

          it "doesn't create a new one" do
            random_content = "content #{rand}"
            File.open('spec/spec_helper.rb', 'w') {|f| f << random_content}
            command_line_config.run
            expect(File.read('spec/spec_helper.rb')).to eq(random_content)
          end
        end
      end
    end

    describe "#run", "with a target directory" do
      subject(:command_line_config) {
        ProjectInitializer.new(:destination => tmpdir, :report_stream => StringIO.new)
      }

      let(:tmpdir) { 'relative/destination/' }

      before { FileUtils.mkdir_p(tmpdir) }

      context "with no .rspec file" do
        it "generates a .rspec" do
          command_line_config.run
          expect(File.read(File.join(tmpdir, '.rspec'))).to match(/--require spec_helper/m)
        end
      end

      context "with a .rspec file" do
        it "doesn't create a new one" do
          dot_rspec_file = File.join(tmpdir, '.rspec')
          File.open(dot_rspec_file, 'w') {|f| f << '--not-a-real-flag'}
          command_line_config.run
          expect(File.read(dot_rspec_file)).to eq('--not-a-real-flag')
        end
      end

      context "with no spec/spec_helper.rb file" do
        it "generates a spec/spec_helper.rb" do
          command_line_config.run
          expect(File.read(File.join(tmpdir, 'spec/spec_helper.rb'))).to match(/RSpec\.configure do \|config\|/m)
        end
      end

      context "with a spec/spec_helper.rb file" do
        it "doesn't create a new one" do
          FileUtils.mkdir File.join(tmpdir, 'spec')
          spec_helper_file = File.join(tmpdir, 'spec', 'spec_helper.rb')
          random_content = "content #{rand}"
          File.open(spec_helper_file, 'w') {|f| f << random_content}
          command_line_config.run
          expect(File.read(spec_helper_file)).to eq(random_content)
        end
      end
    end

  end
end
