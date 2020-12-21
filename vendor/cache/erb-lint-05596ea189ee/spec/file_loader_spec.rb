# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::FileLoader do
  let(:yaml_content) { "---\nmy_yaml_config: 123" }
  let(:base_path) { '/path/to/app' }
  let(:filename) { '.config.yml' }
  let(:file_loader) { described_class.new(base_path) }
  subject(:yaml) { file_loader.yaml(filename) }

  before do
    allow(File).to(receive(:read).with("#{base_path}/#{filename}").and_return(yaml_content))
  end

  describe '.yaml' do
    context "it reads the file from disk" do
      it { expect(subject).to(eq('my_yaml_config' => 123)) }
    end

    context "it allows regexp to be loaded" do
      let(:yaml_content) { <<~YAML }
        ---
        some_config:
          - !ruby/regexp /\\Afoo/i
      YAML
      it { expect(subject).to(eq('some_config' => [/\Afoo/i])) }
    end

    context "it allows symbol to be loaded" do
      let(:yaml_content) { <<~YAML }
        ---
        :some_config: :symbol
      YAML
      it { expect(subject).to(eq(some_config: :symbol)) }
    end

    context "it does not allow other objects to be loaded" do
      let(:yaml_content) { <<~YAML }
        ---
        some_config:
          - !ruby/array:Array
            - fooo
      YAML
      it { expect { subject }.to(raise_exception(Psych::DisallowedClass)) }
    end
  end
end
