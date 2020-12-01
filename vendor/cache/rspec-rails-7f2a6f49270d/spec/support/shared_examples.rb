require 'pathname'

shared_examples_for "an rspec-rails example group mixin" do |type, *paths|
  let(:mixin) { described_class }

  def define_group_in(path, group_definition)
    path = Pathname(path)
    $_new_group = nil
    begin
      file = path + "whatever_spec.rb"

      Dir.mktmpdir("rspec-rails-app-root") do |dir|
        Dir.chdir(dir) do
          path.mkpath
          File.open(file, "w") do |f|
            f.write("$_new_group = #{group_definition}")
          end

          load file
        end
      end

      group = $_new_group
      return group
    ensure
      $_new_group = nil
    end
  end

  it "adds does not add `:type` metadata on inclusion" do
    mixin = self.mixin
    group = RSpec.describe { include mixin }
    expect(group.metadata).not_to include(:type)
  end

  context 'when `infer_spec_type_from_file_location!` is configured' do
    before { RSpec.configuration.infer_spec_type_from_file_location! }

    paths.each do |path|
      context "for an example group defined in a file in the #{path} directory" do
        it "includes itself in the example group" do
          group = define_group_in path, "RSpec.describe"
          expect(group.included_modules).to include(mixin)
        end

        it "tags groups in that directory with `:type => #{type.inspect}`" do
          group = define_group_in path, "RSpec.describe"
          expect(group.metadata).to include(type: type)
        end

        it "allows users to override the type" do
          group = define_group_in path, "RSpec.describe 'group', :type => :other"
          expect(group.metadata).to include(type: :other)
          expect(group.included_modules).not_to include(mixin)
        end

        it "applies configured `before(:context)` hooks with `:type => #{type.inspect}` metadata" do
          block_run = false
          RSpec.configuration.before(:context, type: type) { block_run = true }

          group = define_group_in path, "RSpec.describe('group') { it { } }"
          group.run(double.as_null_object)

          expect(block_run).to eq(true)
        end
      end
    end

    it "includes itself in example groups tagged with `:type => #{type.inspect}`" do
      group = define_group_in "spec/other", "RSpec.describe 'group', :type => #{type.inspect}"
      expect(group.included_modules).to include(mixin)
    end
  end

  context 'when `infer_spec_type_from_file_location!` is not configured' do
    it "includes itself in example groups tagged with `:type => #{type.inspect}`" do
      group = define_group_in "spec/other", "RSpec.describe 'group', :type => #{type.inspect}"
      expect(group.included_modules).to include(mixin)
    end

    paths.each do |path|
      context "for an example group defined in a file in the #{path} directory" do
        it "does not include itself in the example group" do
          group = define_group_in path, "RSpec.describe"
          expect(group.included_modules).not_to include(mixin)
        end

        it "does not tag groups in that directory with `:type => #{type.inspect}`" do
          group = define_group_in path, "RSpec.describe"
          expect(group.metadata).not_to include(:type)
        end
      end
    end
  end
end
