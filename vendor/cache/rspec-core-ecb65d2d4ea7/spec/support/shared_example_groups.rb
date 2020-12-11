RSpec.shared_examples_for "metadata hash builder" do
  let(:hash) { metadata_hash(:foo, :bar, :bazz => 23) }

  it 'treats symbols as metadata keys with a true value' do
    expect(hash[:foo]).to be(true)
    expect(hash[:bar]).to be(true)
  end

  it 'still processes hash values normally' do
    expect(hash[:bazz]).to be(23)
  end
end

RSpec.shared_examples_for "handling symlinked directories when loading spec files" do
  include_context "isolated directory"
  let(:project_dir) { Dir.getwd }

  before(:example) do
    pending "Windows does not support symlinking on RUBY_VERSION < 2.3"
  end if RSpec::Support::OS.windows? && RUBY_VERSION < '2.3'

  it "finds the files" do
    foos_dir = File.join(project_dir, "spec/foos")
    FileUtils.mkdir_p foos_dir
    FileUtils.touch(File.join(foos_dir, "foo_spec.rb"))

    bars_dir = File.join(Dir.tmpdir, "shared/spec/bars")
    FileUtils.mkdir_p bars_dir
    FileUtils.touch(File.join(bars_dir, "bar_spec.rb"))

    FileUtils.ln_s bars_dir, File.join(project_dir, "spec/bars")

    expect(loaded_files).to contain_files(
      "spec/bars/bar_spec.rb",
      "spec/foos/foo_spec.rb"
    )
  end

  it "works on a more complicated example (issue 1113)" do
    FileUtils.mkdir_p("subtrees/DD/spec")
    FileUtils.mkdir_p("spec/lib")
    FileUtils.touch("subtrees/DD/spec/dd_foo_spec.rb")
    FileUtils.ln_s(File.join(project_dir, "subtrees/DD/spec"), "spec/lib/DD")

    expect(loaded_files).to contain_files("spec/lib/DD/dd_foo_spec.rb")
  end
end
