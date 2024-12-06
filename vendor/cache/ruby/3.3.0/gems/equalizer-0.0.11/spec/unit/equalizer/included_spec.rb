# encoding: utf-8

require 'spec_helper'

describe Equalizer, '#included' do
  subject { descendant.instance_exec(object) { |mod| include mod } }

  let(:object)     { described_class.new        }
  let(:descendant) { Class.new                  }
  let(:superclass) { described_class.superclass }

  before do
    # Prevent Module.included from being called through inheritance
    allow(described_class::Methods).to receive(:included)
  end

  around do |example|
    # Restore included method after each example
    superclass.class_eval do
      alias_method :original_included, :included
      example.call
      undef_method :included
      alias_method :included, :original_included
    end
  end

  it 'delegates to the superclass #included method' do
    # This is the most succinct approach I could think of to test whether the
    # superclass#included method is called. All of the built-in rspec helpers
    # did not seem to work for this.
    included = false

    superclass.class_eval do
      define_method(:included) do |_|
        # Only set the flag when an Equalizer instance is included.
        # Otherwise, other module includes (which get triggered internally
        # in RSpec when `change` is used for the first time, since it uses
        # autoloading for its matchers) will wrongly set this flag.
        included = true if self.kind_of?(Equalizer)
      end
    end

    expect { subject }.to change { included }.from(false).to(true)
  end

  it 'includes methods into the descendant' do
    subject
    expect(descendant.included_modules).to include(described_class::Methods)
  end
end
