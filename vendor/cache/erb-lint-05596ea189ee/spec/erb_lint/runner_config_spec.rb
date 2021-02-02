# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::RunnerConfig do
  describe '.default' do
    it 'returns expected class' do
      expect(described_class.default.class).to(be(described_class))
    end

    it 'has default linters enabled' do
      expect(described_class.default.for_linter('FinalNewline').enabled?).to(be(true))
    end

    it 'disables default linters if asked to do so' do
      expect(
        described_class
          .default(default_enabled: false)
          .for_linter('FinalNewline').enabled?
      ).to(be(false))
    end
  end

  describe '.default_for' do
    let(:enabled_default_linters) do
      described_class.default(default_enabled: true)
    end

    let(:disabled_default_linters) do
      described_class.default(default_enabled: false)
    end

    context 'without EnableDefaultLinters option' do
      let(:config_hash) do
        { foo: true }.deep_stringify_keys
      end

      subject { described_class.default_for(config_hash) }
      it 'enables the default linters' do
        expect(subject.to_hash["linters"].to_json).to(eq(enabled_default_linters.to_hash["linters"].to_json))
      end
    end

    context 'with EnableDefaultLinters option set to true' do
      let(:config_hash) do
        { "EnableDefaultLinters" => true }
      end

      subject { described_class.default_for(config_hash) }
      it 'enables the default linters' do
        expect(subject.to_hash["linters"].to_json).to(eq(enabled_default_linters.to_hash["linters"].to_json))
      end
    end

    context 'with EnableDefaultLinters set to false' do
      let(:config_hash) do
        { "EnableDefaultLinters" => false }
      end

      subject { described_class.default_for(config_hash) }
      it 'disables the default linters' do
        expect(subject.to_hash["linters"].to_json).to(eq(disabled_default_linters.to_hash["linters"].to_json))
      end
    end
  end

  context 'with custom config' do
    let(:runner_config) { described_class.new(config_hash) }

    describe '#to_hash' do
      subject { runner_config.to_hash }

      context 'with empty hash' do
        let(:config_hash) { {} }

        it { expect(subject).to(eq({})) }
      end

      context 'with custom data' do
        let(:config_hash) { { foo: true } }

        it { expect(subject).to(eq('foo' => true)) }
      end
    end

    describe '#for_linter' do
      subject { runner_config.for_linter(linter) }

      class MyCustomLinter < ERBLint::Linter
        class MySchema < ERBLint::LinterConfig
          property :my_option
        end
        self.config_schema = MySchema
      end

      before do
        allow(ERBLint::LinterRegistry).to(receive(:linters)
          .and_return([ERBLint::Linters::FinalNewline, MyCustomLinter]))
      end

      context 'with string argument' do
        let(:linter) { 'MyCustomLinter' }
        let(:config_hash) { { linters: { 'MyCustomLinter' => { 'my_option' => 'custom value' } } } }

        it { expect(subject.class).to(eq(MyCustomLinter::MySchema)) }
        it { expect(subject['my_option']).to(eq('custom value')) }
      end

      context 'with class argument' do
        let(:linter) { MyCustomLinter }
        let(:config_hash) { { linters: { 'MyCustomLinter' => { my_option: 'custom value' } } } }

        it { expect(subject.class).to(eq(MyCustomLinter::MySchema)) }
      end

      context 'with argument that isnt a string and does not inherit from Linter' do
        let(:linter) { Object }
        let(:config_hash) { { linters: { 'MyCustomLinter' => { my_option: 'custom value' } } } }

        it { expect { subject }.to(raise_error(ArgumentError, "expected String or linter class")) }
      end

      context 'for linter not present in config hash' do
        let(:linter) { 'FinalNewline' }
        let(:config_hash) {}

        it { expect(subject.class).to(eq(ERBLint::Linters::FinalNewline::ConfigSchema)) }
        it 'fills linter config with defaults from schema' do
          expect(subject.to_hash).to(eq("enabled" => false, "exclude" => [], "present" => true))
        end
        it 'is disabled by default' do
          expect(subject.enabled?).to(eq(false))
        end
      end

      context 'when global excludes are specified' do
        let(:linter) { MyCustomLinter }
        let(:config_hash) do
          {
            linters: {
              'MyCustomLinter' => { exclude: ['foo/bar.rb'] },
            },
            exclude: [
              '**/node_modules/**',
            ],
          }
        end

        it 'excluded files are merged' do
          expect(subject.exclude).to(eq(['foo/bar.rb', '**/node_modules/**']))
        end
      end
    end

    describe '#merge' do
      let(:first_config) { described_class.new(foo: 1) }
      let(:second_config) { described_class.new(bar: 2) }
      subject { first_config.merge(second_config) }

      context 'creates a new object' do
        it { expect(subject.class).to(be(described_class)) }
        it { expect(subject).to_not(be(first_config)) }
        it { expect(subject).to_not(be(second_config)) }
      end

      context 'new object has keys from both configs' do
        it { expect(subject.to_hash).to(eq('foo' => 1, 'bar' => 2)) }
      end

      context 'second object overwrites keys from first object' do
        let(:second_config) { described_class.new(foo: 42) }
        it { expect(subject.to_hash).to(eq('foo' => 42)) }
      end

      context 'performs a deep merge' do
        let(:first_config) { described_class.new(nested: { foo: 1 }) }
        let(:second_config) { described_class.new(nested: { bar: 2 }) }
        it { expect(subject.to_hash).to(eq('nested' => { 'foo' => 1, 'bar' => 2 })) }
      end
    end

    describe '#merge!' do
      let(:first_config) { described_class.new(foo: 1) }
      let(:second_config) { described_class.new(bar: 2) }
      subject { first_config.merge!(second_config) }

      context 'returns first object' do
        it { expect(subject).to(be(first_config)) }
      end

      context 'first object has keys from both configs' do
        it { expect(subject.to_hash).to(eq('foo' => 1, 'bar' => 2)) }
      end

      context 'second object overwrites keys from first object' do
        let(:second_config) { described_class.new(foo: 42) }
        it { expect(subject.to_hash).to(eq('foo' => 42)) }
      end

      context 'performs a deep merge' do
        let(:first_config) { described_class.new(nested: { foo: 1 }) }
        let(:second_config) { described_class.new(nested: { bar: 2 }) }
        it { expect(subject.to_hash).to(eq('nested' => { 'foo' => 1, 'bar' => 2 })) }
      end
    end

    skip "inheritance" do
      let(:tmp_root) { 'tmp' }
      let(:gem_root) { "#{tmp_root}/gems" }

      after { FileUtils.rm_rf(tmp_root) }

      it "inherits from a gem and loads the config" do
        create_file("#{gem_root}/gemone/config/erb-lint.yml", <<-YAML.strip_indent)
          MyCustomLinter:
            my_option: custom value
        YAML

        gem_class = Struct.new(:gem_dir)
        %w(gemone).each do |gem_name|
          mock_spec = gem_class.new(File.join(gem_root, gem_name))
          expect(Gem::Specification).to(receive(:find_by_name)
            .at_least(:once).with(gem_name).and_return(mock_spec))
        end

        runner_config = described_class.new({
          'inherit_gem' => {
            'gemone' => 'config/erb-lint.yml',
          },
        }, ERBLint::FileLoader.new(Dir.pwd))

        expect(runner_config.to_hash['MyCustomLinter']).to(eq("my_option" => "custom value"))
      end

      it "inherits from a gem and merges the config" do
        create_file("#{gem_root}/gemone/config/erb-lint.yml", <<-YAML.strip_indent)
          MyCustomLinter1:
            a: value to be overwritten
            b: value for b
        YAML

        gem_class = Struct.new(:gem_dir)
        %w(gemone).each do |gem_name|
          mock_spec = gem_class.new(File.join(gem_root, gem_name))
          expect(Gem::Specification).to(receive(:find_by_name)
            .at_least(:once).with(gem_name).and_return(mock_spec))
        end

        runner_config = described_class.new({
          'inherit_gem' => {
            'gemone' => 'config/erb-lint.yml',
          },
          'MyCustomLinter1' => {
            'a' => 'value for a',
            'c' => 'value for c',
          },
          'MyCustomLinter2' => {
            'd' => 'value for d',
          },
        }, ERBLint::FileLoader.new(Dir.pwd))

        config_hash = runner_config.to_hash
        expect(config_hash['MyCustomLinter1']).to(eq("a" => "value for a", "b" => "value for b", "c" => "value for c"))
        expect(config_hash['MyCustomLinter2']).to(eq("d" => "value for d"))
      end

      it "inherits from a file and merges the config" do
        create_file("#{tmp_root}/erb-lint-default.yml", <<-YAML.strip_indent)
          MyCustomLinter1:
            a: value to be overwritten
            b: value for b
        YAML

        runner_config = described_class.new({
          'inherit_from' => "#{tmp_root}/erb-lint-default.yml",
          'MyCustomLinter1' => {
            'a' => 'value for a',
            'c' => 'value for c',
          },
          'MyCustomLinter2' => {
            'd' => 'value for d',
          },
        }, ERBLint::FileLoader.new(Dir.pwd))

        config_hash = runner_config.to_hash
        expect(config_hash['MyCustomLinter1']).to(eq("a" => "value for a", "b" => "value for b", "c" => "value for c"))
        expect(config_hash['MyCustomLinter2']).to(eq("d" => "value for d"))
      end

      it "does not inherit from a file if file loader is not provided" do
        create_file("#{tmp_root}/erb-lint-default.yml", <<-YAML.strip_indent)
          MyCustomLinter1:
            a: value to be overwritten
            b: value for b
        YAML

        runner_config = described_class.new(
          'inherit_from' => "#{tmp_root}/erb-lint-default.yml",
          'MyCustomLinter1' => {
            'a' => 'value for a',
            'c' => 'value for c',
          },
          'MyCustomLinter2' => {
            'd' => 'value for d',
          },
        )

        config_hash = runner_config.to_hash
        expect(config_hash['MyCustomLinter1']).to(eq("a" => "value for a", "c" => "value for c"))
        expect(config_hash['MyCustomLinter2']).to(eq("d" => "value for d"))
      end

      it "inherits from a gem if file load is not provided" do
        create_file("#{gem_root}/gemone/config/erb-lint.yml", <<-YAML.strip_indent)
          MyCustomLinter:
            my_option: custom value
        YAML

        gem_class = Struct.new(:gem_dir)
        %w(gemone).each do |gem_name|
          mock_spec = gem_class.new(File.join(gem_root, gem_name))
          expect(Gem::Specification).to(receive(:find_by_name)
            .at_least(:once).with(gem_name).and_return(mock_spec))
        end

        runner_config = described_class.new(
          'inherit_gem' => {
            'gemone' => 'config/erb-lint.yml',
          },
        )

        expect(runner_config.to_hash).to(eq({}))
      end
    end
  end

  private

  def create_file(file_path, content)
    file_path = File.expand_path(file_path)

    dir_path = File.dirname(file_path)
    FileUtils.makedirs(dir_path) unless File.exist?(dir_path)

    File.open(file_path, 'w') do |file|
      case content
      when String
        file.puts content
      when Array
        file.puts content.join("\n")
      end
    end
  end
end
