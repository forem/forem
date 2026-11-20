require "rails_helper"

RSpec.describe "ForemNative tasks", type: :task do
  describe "forem_native:benchmark_transcript" do
    before do
      Rake.application["forem_native:benchmark_transcript"].reenable
    end

    it "rejects older binaries before measuring the renderer's Ruby fallback" do
      allow(ForemNative::Native).to receive(:respond_to?).and_call_original
      allow(ForemNative::Native).to receive(:respond_to?).with(:postprocess_transcript_html).and_return(false)
      allow(AgentSessionRenderers::MarkdownRenderer).to receive(:highlight_code_blocks).and_call_original

      expect { Rake::Task["forem_native:benchmark_transcript"].invoke }
        .to raise_error(RuntimeError, /rebuild with `bundle exec rake forem_native:compile` before benchmarking/)
      expect(AgentSessionRenderers::MarkdownRenderer).not_to have_received(:highlight_code_blocks)
    end
  end
end
