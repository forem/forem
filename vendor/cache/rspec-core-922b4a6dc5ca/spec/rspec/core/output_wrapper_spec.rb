module RSpec::Core
  RSpec.describe OutputWrapper do
    let(:output) { StringIO.new }
    let(:wrapper) { OutputWrapper.new(output) }

    it 'redirects calls to the wrapped object' do
      wrapper.puts('message')
      wrapper.print('another message')
      expect(output.string).to eq("message\nanother message").and eq(wrapper.string)
    end

    describe '#output=' do
      let(:another_output) { StringIO.new }

      it 'changes the output stream' do
        wrapper.output = another_output
        wrapper.puts('message')
        expect(another_output.string).to eq("message\n")
      end
    end
  end
end
