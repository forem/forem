require 'rspec/core/formatters/progress_formatter'

RSpec.describe RSpec::Core::Formatters::ProgressFormatter do
  include FormatterSupport

  before do
    send_notification :start, start_notification(2)
  end

  it 'prints a . on example_passed' do
    send_notification :example_passed, example_notification
    expect(formatter_output.string).to eq(".")
  end

  it 'prints a * on example_pending' do
    send_notification :example_pending, example_notification
    expect(formatter_output.string).to eq("*")
  end

  it 'prints a F on example_failed' do
    send_notification :example_failed, example_notification
    expect(formatter_output.string).to eq("F")
  end

  it "produces standard summary without pending when pending has a 0 count" do
    send_notification :dump_summary, summary_notification(0.00001, examples(2), [], [], 0)
    expect(formatter_output.string).to match(/^\n/)
    expect(formatter_output.string).to match(/2 examples, 0 failures/i)
    expect(formatter_output.string).not_to match(/0 pending/i)
  end

  it "pushes nothing on start" do
    #start already sent
    expect(formatter_output.string).to eq("")
  end

  it "pushes nothing on start dump" do
    send_notification :start_dump, null_notification
    expect(formatter_output.string).to eq("\n")
  end

  # The backtrace is slightly different on JRuby/Rubinius so we skip there.
  it 'produces the expected full output', :if => RSpec::Support::Ruby.mri? do
    output = run_example_specs_with_formatter("progress")
    output.gsub!(/ +$/, '') # strip trailing whitespace

    expect(output).to eq(<<-EOS.gsub(/^\s+\|/, ''))
      |**F..FFFFF
      |
      |#{expected_summary_output_for_example_specs}

    EOS
  end
end
