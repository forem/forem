require 'support/aruba_support'
require 'support/formatter_support'

RSpec.describe 'Suite hook errors' do
  include_context "aruba support"
  include FormatterSupport

  let(:failure_exit_code) { rand(97) + 2 } # 2..99
  let(:error_exit_code) { failure_exit_code + 2 } # 4..101

  if RSpec::Support::Ruby.jruby_9000? && RSpec::Support::Ruby.jruby_version > '9.2.0.0'
    let(:spec_line_suffix) { ":in `block in <main>'" }
  elsif RSpec::Support::Ruby.jruby_9000?
    let(:spec_line_suffix) { ":in `block in (root)'" }
  elsif RSpec::Support::Ruby.jruby?
    let(:spec_line_suffix) { ":in `(root)'" }
  elsif RUBY_VERSION == "1.8.7"
    let(:spec_line_suffix) { "" }
  else
    let(:spec_line_suffix) { ":in `block (2 levels) in <top (required)>'" }
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

  def run_spec_expecting_non_zero(before_or_after)
    write_file "the_spec.rb", "
      RSpec.configure do |c|
        c.#{before_or_after}(:suite) do
          raise 'boom'
        end
      end

      RSpec.describe do
        it { }
      end
    "

    run_command "the_spec.rb"
    expect(last_cmd_exit_status).to eq(error_exit_code)
    normalize_durations(last_cmd_stdout)
  end

  it 'nicely formats errors in `before(:suite)` hooks and exits with non-zero' do
    output = run_spec_expecting_non_zero(:before)
    expect(output).to eq unindent(<<-EOS)

      An error occurred in a `before(:suite)` hook.
      Failure/Error: raise 'boom'

      RuntimeError:
        boom
      # ./the_spec.rb:4#{spec_line_suffix}


      Finished in n.nnnn seconds (files took n.nnnn seconds to load)
      0 examples, 0 failures, 1 error occurred outside of examples

    EOS
  end

  it 'nicely formats errors in `after(:suite)` hooks and exits with non-zero' do
    output = run_spec_expecting_non_zero(:after)
    expect(output).to eq unindent(<<-EOS)
      .
      An error occurred in an `after(:suite)` hook.
      Failure/Error: raise 'boom'

      RuntimeError:
        boom
      # ./the_spec.rb:4#{spec_line_suffix}


      Finished in n.nnnn seconds (files took n.nnnn seconds to load)
      1 example, 0 failures, 1 error occurred outside of examples

    EOS
  end

  it 'nicely formats errors from multiple :suite hooks of both types and exits with non-zero' do
    write_file "the_spec.rb", "
      RSpec.configure do |c|
        c.before(:suite) { raise 'before 1' }
        c.before(:suite) { raise 'before 2' }
        c.after(:suite) { raise 'after 1' }
        c.after(:suite) { raise 'after 2' }
      end

      RSpec.describe do
        it { }
      end
    "

    cause =
      if RSpec::Support::Ruby.jruby_9000? && RSpec::Support::Ruby.jruby_version > '9.2.0.0'
        unindent(<<-EOS)
          # ------------------
          # --- Caused by: ---
          # RuntimeError:
          #   before 1
          #   ./the_spec.rb:3:in `block in <main>'
        EOS
      else
        ""
      end

    run_command "the_spec.rb"
    expect(last_cmd_exit_status).to eq(error_exit_code)
    output = normalize_durations(last_cmd_stdout)

    expect(output).to eq unindent(<<-EOS)

      An error occurred in a `before(:suite)` hook.
      Failure/Error: c.before(:suite) { raise 'before 1' }

      RuntimeError:
        before 1
      # ./the_spec.rb:3#{spec_line_suffix}

      An error occurred in an `after(:suite)` hook.
      Failure/Error: c.after(:suite) { raise 'after 2' }

      RuntimeError:
        after 2
      # ./the_spec.rb:6#{spec_line_suffix}
      #{ cause }
      An error occurred in an `after(:suite)` hook.
      Failure/Error: c.after(:suite) { raise 'after 1' }

      RuntimeError:
        after 1
      # ./the_spec.rb:5#{spec_line_suffix}
      #{ cause }

      Finished in n.nnnn seconds (files took n.nnnn seconds to load)
      0 examples, 0 failures, 3 errors occurred outside of examples

    EOS
  end
end
