require 'support/aruba_support'
require 'support/formatter_support'

RSpec.describe 'Spec file load errors' do
  include_context "aruba support"
  include FormatterSupport

  let(:failure_exit_code) { rand(97) + 2 } # 2..99
  let(:error_exit_code) { failure_exit_code + 1 } # 3..100

  if RSpec::Support::Ruby.jruby_9000?
    let(:spec_line_suffix) { ":in `<main>'" }
  elsif RSpec::Support::Ruby.jruby?
    let(:spec_line_suffix) { ":in `(root)'" }
  elsif RUBY_VERSION == "1.8.7"
    let(:spec_line_suffix) { "" }
  else
    let(:spec_line_suffix) { ":in `<top (required)>'" }
  end

  before do
    setup_aruba

    RSpec.configure do |c|
      c.filter_gems_from_backtrace "gems/aruba"
      c.backtrace_exclusion_patterns << %r{/rspec-core/spec/} << %r{rspec_with_simplecov}
      c.failure_exit_code = failure_exit_code
      c.error_exit_code = error_exit_code
    end
  end

  it 'nicely handles load-time errors from --require files' do
    write_file_formatted "helper_with_error.rb", "raise 'boom'"

    run_command "--require ./helper_with_error"
    expect(last_cmd_exit_status).to eq(error_exit_code)
    output = normalize_durations(last_cmd_stdout)
    expect(output).to eq unindent(<<-EOS)

      An error occurred while loading ./helper_with_error.
      Failure/Error: raise 'boom'

      RuntimeError:
        boom
      # ./helper_with_error.rb:1#{spec_line_suffix}
      No examples found.


      Finished in n.nnnn seconds (files took n.nnnn seconds to load)
      0 examples, 0 failures, 1 error occurred outside of examples

    EOS
  end

  it 'prints a single error when it happens on --require files' do
    write_file_formatted "helper_with_error.rb", "raise 'boom'"

    write_file_formatted "1_spec.rb", "
      RSpec.describe 'A broken spec file that will raise when loaded' do
        raise 'kaboom'
      end
    "

    run_command "--require ./helper_with_error 1_spec.rb"
    expect(last_cmd_exit_status).to eq(error_exit_code)
    output = normalize_durations(last_cmd_stdout)
    expect(output).to eq unindent(<<-EOS)

      An error occurred while loading ./helper_with_error.
      Failure/Error: raise 'boom'

      RuntimeError:
        boom
      # ./helper_with_error.rb:1#{spec_line_suffix}
      No examples found.


      Finished in n.nnnn seconds (files took n.nnnn seconds to load)
      0 examples, 0 failures, 1 error occurred outside of examples

    EOS
  end

  it 'nicely handles load-time errors in user spec files' do
    write_file_formatted "1_spec.rb", "
      boom

      RSpec.describe 'Calling boom' do
        it 'will not run this example' do
          expect(1).to eq 1
        end
      end
    "

    write_file_formatted "2_spec.rb", "
      RSpec.describe 'No Error' do
        it 'will not run this example, either' do
          expect(1).to eq 1
        end
      end
    "

    write_file_formatted "3_spec.rb", "
      boom

      RSpec.describe 'Calling boom again' do
        it 'will not run this example, either' do
          expect(1).to eq 1
        end
      end
    "

    run_command "1_spec.rb 2_spec.rb 3_spec.rb"
    expect(last_cmd_exit_status).to eq(error_exit_code)
    output = normalize_durations(last_cmd_stdout)
    expect(output).to eq unindent(<<-EOS)

      An error occurred while loading ./1_spec.rb.
      Failure/Error: boom

      NameError:
        undefined local variable or method `boom' for main:Object
      # ./1_spec.rb:1#{spec_line_suffix}

      An error occurred while loading ./3_spec.rb.
      Failure/Error: boom

      NameError:
        undefined local variable or method `boom' for main:Object
      # ./3_spec.rb:1#{spec_line_suffix}


      Finished in n.nnnn seconds (files took n.nnnn seconds to load)
      0 examples, 0 failures, 2 errors occurred outside of examples

    EOS
  end
end
