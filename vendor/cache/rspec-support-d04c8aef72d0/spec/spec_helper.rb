require 'rspec/support/spec'
RSpec::Support::Spec.setup_simplecov

RSpec::Matchers.define_negated_matcher :avoid_raising_errors, :raise_error
RSpec::Matchers.define_negated_matcher :avoid_changing, :change
