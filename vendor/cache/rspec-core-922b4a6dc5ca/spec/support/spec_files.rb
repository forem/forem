RSpec.shared_context "spec files" do
  def failing_spec_filename
    @failing_spec_filename ||= File.expand_path(File.dirname(__FILE__)) + "/_failing_spec.rb"
  end

  def passing_spec_filename
    @passing_spec_filename ||= File.expand_path(File.dirname(__FILE__)) + "/_passing_spec.rb"
  end

  def create_passing_spec_file
    File.open(passing_spec_filename, 'w') do |f|
      f.write %q{
        RSpec.describe "passing spec" do
          it "passes" do
            expect(1).to eq(1)
          end
        end
      }
    end
  end

  def create_failing_spec_file
    File.open(failing_spec_filename, 'w') do |f|
      f.write %q{
        RSpec.describe "failing spec" do
          it "fails" do
            expect(1).to eq(2)
          end
        end
      }
    end
  end

  before(:all) do
    create_passing_spec_file
    create_failing_spec_file
  end

  after(:all) do
    File.delete(passing_spec_filename)
    File.delete(failing_spec_filename)
  end

end
