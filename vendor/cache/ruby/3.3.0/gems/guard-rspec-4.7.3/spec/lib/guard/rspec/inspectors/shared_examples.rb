RSpec.shared_examples "inspector" do |klass|
  let(:spec_paths) { %w(spec myspec) }
  let(:options) { { custom: "value", spec_paths: spec_paths } }
  let(:inspector) { klass.new(options) }

  # Use real paths because BaseInspector#_clean will be used to clean them
  let(:paths) do
    [
      "spec/lib/guard/rspec/inspectors/base_inspector_spec.rb",
      "spec/lib/guard/rspec/runner_spec.rb",
      "spec/lib/guard/rspec/deprecator_spec.rb"
    ]
  end
  let(:failed_locations) do
    [
      "./spec/lib/guard/rspec/runner_spec.rb:12",
      "./spec/lib/guard/rspec/deprecator_spec.rb:55"
    ]
  end

  describe ".initialize" do
    it "sets options and spec_paths" do
      expect(inspector.options).to include(:custom, :spec_paths)
      expect(inspector.options[:custom]).to eq("value")
      expect(inspector.spec_paths).to eq(spec_paths)
    end
  end

  describe "#paths" do
    before do
      allow(Dir).to receive(:[]).with("myspec/**{,/*/**}/*[_.]spec.rb").
        and_return([])

      allow(Dir).to receive(:[]).with("myspec/**{,/*/**}/*.feature").
        and_return([])

      allow(Dir).to receive(:[]).with("spec/**{,/*/**}/*.feature").
        and_return([])
    end

    it "returns paths when called first time" do
      allow(File).to receive(:directory?).
        with("spec/lib/guard/rspec/inspectors/base_inspector_spec.rb").
        and_return(false)

      allow(File).to receive(:directory?).
        with("spec/lib/guard/rspec/runner_spec.rb").
        and_return(false)

      allow(File).to receive(:directory?).
        with("spec/lib/guard/rspec/deprecator_spec.rb").
        and_return(false)

      allow(Dir).to receive(:[]).with("spec/**{,/*/**}/*[_.]spec.rb").
        and_return(paths)

      expect(inspector.paths(paths)).to match_array(paths)
    end

    it "does not return non-spec paths" do
      paths = %w(not_a_spec_path.rb spec/not_exist_spec.rb)

      allow(File).to receive(:directory?).with("not_a_spec_path.rb").
        and_return(false)

      allow(File).to receive(:directory?).with("spec/not_exist_spec.rb").
        and_return(false)

      allow(Dir).to receive(:[]).with("spec/**{,/*/**}/*[_.]spec.rb").
        and_return([])

      expect(inspector.paths(paths)).to eq([])
    end

    it "uniq and compact paths" do
      allow(File).to receive(:directory?).
        with("spec/lib/guard/rspec/inspectors/base_inspector_spec.rb").
        and_return(false)

      allow(File).to receive(:directory?).
        with("spec/lib/guard/rspec/runner_spec.rb").
        and_return(false)

      allow(File).to receive(:directory?).
        with("spec/lib/guard/rspec/deprecator_spec.rb").
        and_return(false)

      allow(Dir).to receive(:[]).with("spec/**{,/*/**}/*[_.]spec.rb").
        and_return(paths)

      expect(inspector.paths(paths + paths + [nil, nil, nil])).
        to match_array(paths)
    end

    # NOTE: I'm not sure that it is totally correct behaviour
    it "return spec_paths and directories too" do
      allow(File).to receive(:directory?).with("myspec").and_return(true)
      allow(File).to receive(:directory?).with("lib/guard").and_return(true)
      allow(File).to receive(:directory?).
        with("not_exist_dir").and_return(false)

      allow(Dir).to receive(:[]).with("spec/**{,/*/**}/*[_.]spec.rb").
        and_return([])

      paths = %w(myspec lib/guard not_exist_dir)
      expect(inspector.paths(paths)).to match_array(paths - ["not_exist_dir"])
    end
  end

  describe "#failed" do
    it "is callable" do
      expect { inspector.failed(failed_locations) }.not_to raise_error
    end
  end

  describe "#reload" do
    it "is callable" do
      expect { inspector.reload }.not_to raise_error
    end
  end
end
