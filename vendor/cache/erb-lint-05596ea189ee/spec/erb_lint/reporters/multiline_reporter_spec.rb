# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Reporters::MultilineReporter do
  describe '.show' do
    subject { described_class.new(stats, autocorrect).show }

    let(:stats) do
      ERBLint::Stats.new(
        found: 2,
        processed_files: {
          'app/views/subscriptions/_loader.html.erb' => offenses,
        }
      )
    end

    let(:offenses) do
      [
        instance_double(ERBLint::Offense,
                        message: 'Extra space detected where there should be no space.',
                        line_number: 1,
                        column: 7),
        instance_double(ERBLint::Offense,
                        message: 'Remove newline before `%>` to match start of tag.',
                        line_number: 52,
                        column: 10),
      ]
    end

    context 'when autocorrect is false' do
      let(:autocorrect) { false }

      it 'displays formatted offenses output' do
        expect { subject }.to(output(<<~MESSAGE).to_stdout)

          Extra space detected where there should be no space.
          In file: app/views/subscriptions/_loader.html.erb:1

          Remove newline before `%>` to match start of tag.
          In file: app/views/subscriptions/_loader.html.erb:52

        MESSAGE
      end
    end

    context 'when autocorrect is true' do
      let(:autocorrect) { true }

      it 'displays not autocorrected warning' do
        expect { subject }.to(output(/(not autocorrected)/).to_stdout)
      end
    end
  end
end
