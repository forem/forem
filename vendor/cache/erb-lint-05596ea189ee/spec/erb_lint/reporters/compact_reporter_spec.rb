# frozen_string_literal: true

require 'spec_helper'

describe ERBLint::Reporters::CompactReporter do
  describe '.show' do
    subject { described_class.new(stats, false).show }

    let(:stats) do
      ERBLint::Stats.new(
        found: 4,
        processed_files: {
          'app/views/users/show.html.erb' => show_file_offenses,
          'app/views/shared/_notifications.html.erb' => notification_file_offenses,
        }
      )
    end

    let(:show_file_offenses) do
      [
        instance_double(ERBLint::Offense,
                        message: 'Extra space detected where there should be no space.',
                        line_number: 61,
                        column: 10),
        instance_double(ERBLint::Offense,
                        message: 'Remove multiple trailing newline at the end of the file.',
                        line_number: 125,
                        column: 1),
      ]
    end

    let(:notification_file_offenses) do
      [
        instance_double(ERBLint::Offense,
                        message: 'Indent with spaces instead of tabs.',
                        line_number: 3,
                        column: 1),
        instance_double(ERBLint::Offense,
                        message: 'Extra space detected where there should be no space.',
                        line_number: 7,
                        column: 1),
      ]
    end

    it "displays formatted offenses output" do
      expect { subject }.to(output(<<~MESSAGE).to_stdout)
        app/views/users/show.html.erb:61:10: Extra space detected where there should be no space.
        app/views/users/show.html.erb:125:1: Remove multiple trailing newline at the end of the file.
        app/views/shared/_notifications.html.erb:3:1: Indent with spaces instead of tabs.
        app/views/shared/_notifications.html.erb:7:1: Extra space detected where there should be no space.
      MESSAGE
    end
  end
end
