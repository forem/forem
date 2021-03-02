require 'rspec/core/reporter'
require 'rspec/core/formatters/deprecation_formatter'
require 'tempfile'

module RSpec::Core::Formatters
  RSpec.describe DeprecationFormatter do
    include FormatterSupport

    let(:summary_stream) { StringIO.new }

    def notification(hash)
      ::RSpec::Core::Notifications::DeprecationNotification.from_hash(hash)
    end

    before do
      setup_reporter deprecation_stream, summary_stream
    end

    describe "#deprecation" do

      context "with a File deprecation_stream", :slow do
        let(:deprecation_stream) { File.open("#{Dir.tmpdir}/deprecation_summary_example_output", "w+") }

        it "prints a message if provided, ignoring other data" do
          send_notification :deprecation, notification(:message => "this message", :deprecated => "x", :replacement => "y", :call_site => "z")
          deprecation_stream.rewind
          expect(deprecation_stream.read).to eq "this message\n"
        end

        it "surrounds multiline messages in fenceposts" do
          multiline_message = <<-EOS.gsub(/^\s+\|/, '')
            |line one
            |line two
          EOS
          send_notification :deprecation, notification(:message => multiline_message)
          deprecation_stream.rewind

          expected = <<-EOS.gsub(/^\s+\|/, '')
            |--------------------------------------------------------------------------------
            |line one
            |line two
            |--------------------------------------------------------------------------------
          EOS
          expect(deprecation_stream.read).to eq expected
        end

        it "includes the method" do
          send_notification :deprecation, notification(:deprecated => "i_am_deprecated")
          deprecation_stream.rewind
          expect(deprecation_stream.read).to match(/i_am_deprecated is deprecated/)
        end

        it "includes the replacement" do
          send_notification :deprecation, notification(:replacement => "use_me")
          deprecation_stream.rewind
          expect(deprecation_stream.read).to match(/Use use_me instead/)
        end

        it "includes the call site if provided" do
          send_notification :deprecation, notification(:call_site => "somewhere")
          deprecation_stream.rewind
          expect(deprecation_stream.read).to match(/Called from somewhere/)
        end
      end

      context "with an IO deprecation stream" do
        let(:deprecation_stream) { StringIO.new }

        it "prints nothing" do
          5.times { send_notification :deprecation, notification(:deprecated => 'i_am_deprecated') }
          expect(deprecation_stream.string).to eq ""
        end
      end
    end

    describe "#deprecation_summary" do
      let(:summary)   { double }

      context "with a File deprecation_stream", :slow do
        let(:deprecation_stream) { File.open("#{Dir.tmpdir}/deprecation_summary_example_output", "w") }

        it "prints a count of the deprecations" do
          send_notification :deprecation, notification(:deprecated => 'i_am_deprecated')
          send_notification :deprecation_summary, null_notification
          expect(summary_stream.string).to match(/1 deprecation logged to .*deprecation_summary_example_output/)
        end

        it "pluralizes the reported deprecation count for more than one deprecation" do
          send_notification :deprecation, notification(:deprecated => 'i_am_deprecated')
          send_notification :deprecation, notification(:deprecated => 'i_am_deprecated_also')
          send_notification :deprecation_summary, null_notification
          expect(summary_stream.string).to match(/2 deprecations/)
        end

        it "is not printed when there are no deprecations" do
          send_notification :deprecation_summary, null_notification
          expect(summary_stream.string).to eq ""
        end

        it 'uses synchronized/non-buffered output to work around odd duplicate output behavior we have observed' do
          expect {
            send_notification :deprecation, notification(:deprecated => 'foo')
          }.to change { deprecation_stream.sync }.from(false).to(true)
        end

        it 'does not print duplicate messages' do
          3.times { send_notification :deprecation, notification(:deprecated => 'foo') }
          send_notification :deprecation_summary, null_notification

          expect(summary_stream.string).to match(/1 deprecation/)
          expect(File.read(deprecation_stream.path)).to eq("foo is deprecated.\n#{DeprecationFormatter::RAISE_ERROR_CONFIG_NOTICE}")
        end

        it "can handle when the stream is reopened to a system stream", :unless => RSpec::Support::OS.windows? do
          send_notification :deprecation, notification(:deprecated => 'foo')
          deprecation_stream.reopen(IO.for_fd(IO.sysopen('/dev/null', "w+")))
          send_notification :deprecation_summary, null_notification
        end
      end

      context "with an Error deprecation_stream" do
        let(:deprecation_stream) { DeprecationFormatter::RaiseErrorStream.new }

        it 'prints a summary of the number of deprecations found' do
          expect { send_notification :deprecation, notification(:deprecated => 'foo') }.to raise_error(RSpec::Core::DeprecationError)
          send_notification :deprecation_summary, null_notification

          expect(summary_stream.string).to eq("\n1 deprecation found.\n")
        end

        it 'pluralizes the count when it is greater than 1' do
          expect { send_notification :deprecation, notification(:deprecated => 'foo') }.to raise_error(RSpec::Core::DeprecationError)
          expect { send_notification :deprecation, notification(:deprecated => 'bar') }.to raise_error(RSpec::Core::DeprecationError)

          send_notification :deprecation_summary, null_notification

          expect(summary_stream.string).to eq("\n2 deprecations found.\n")
        end
      end

      context "with an IO deprecation_stream" do
        let(:deprecation_stream) { StringIO.new }

        it "groups similar deprecations together" do
          send_notification :deprecation, notification(:deprecated => 'i_am_deprecated', :call_site => "foo.rb:1")
          send_notification :deprecation, notification(:deprecated => 'i_am_a_different_deprecation')
          send_notification :deprecation, notification(:deprecated => 'i_am_deprecated', :call_site => "foo.rb:2")
          send_notification :deprecation_summary, null_notification

          expected = <<-EOS.gsub(/^\s+\|/, '')
            |
            |Deprecation Warnings:
            |
            |i_am_a_different_deprecation is deprecated.
            |
            |i_am_deprecated is deprecated. Called from foo.rb:1.
            |i_am_deprecated is deprecated. Called from foo.rb:2.
            |
            |#{DeprecationFormatter::RAISE_ERROR_CONFIG_NOTICE}
          EOS
          expect(deprecation_stream.string).to eq expected.chomp
        end

        it "limits the deprecation warnings after 3 calls" do
          5.times { |i| send_notification :deprecation, notification(:deprecated => 'i_am_deprecated', :call_site => "foo.rb:#{i + 1}") }
          send_notification :deprecation_summary, null_notification
          expected = <<-EOS.gsub(/^\s+\|/, '')
            |
            |Deprecation Warnings:
            |
            |i_am_deprecated is deprecated. Called from foo.rb:1.
            |i_am_deprecated is deprecated. Called from foo.rb:2.
            |i_am_deprecated is deprecated. Called from foo.rb:3.
            |Too many uses of deprecated 'i_am_deprecated'. #{DeprecationFormatter::DEPRECATION_STREAM_NOTICE}
            |
            |#{DeprecationFormatter::RAISE_ERROR_CONFIG_NOTICE}
          EOS
          expect(deprecation_stream.string).to eq expected.chomp
        end

        it "limits :message deprecation warnings with different callsites after 3 calls" do
          5.times do |n|
            message = "This is a long string with some callsite info: /path/#{n}/to/some/file.rb:2#{n}3.  And some more stuff can come after."
            send_notification :deprecation, notification(:message => message)
          end
          send_notification :deprecation_summary, null_notification
          expected = <<-EOS.gsub(/^\s+\|/, '')
            |
            |Deprecation Warnings:
            |
            |This is a long string with some callsite info: /path/0/to/some/file.rb:203.  And some more stuff can come after.
            |This is a long string with some callsite info: /path/1/to/some/file.rb:213.  And some more stuff can come after.
            |This is a long string with some callsite info: /path/2/to/some/file.rb:223.  And some more stuff can come after.
            |Too many similar deprecation messages reported, disregarding further reports. #{DeprecationFormatter::DEPRECATION_STREAM_NOTICE}
            |
            |#{DeprecationFormatter::RAISE_ERROR_CONFIG_NOTICE}
          EOS
          expect(deprecation_stream.string).to eq expected.chomp
        end

        it "prints the true deprecation count to the summary_stream" do
          5.times { |i| send_notification :deprecation, notification(:deprecated => 'i_am_deprecated', :call_site => "foo.rb:#{i + 1}") }
          5.times do |n|
            send_notification :deprecation, notification(:message => "callsite info: /path/#{n}/to/some/file.rb:2#{n}3.  And some more stuff")
          end
          send_notification :deprecation_summary, null_notification
          expect(summary_stream.string).to match(/10 deprecation warnings total/)
        end

        it 'does not print duplicate messages' do
          3.times { send_notification :deprecation, notification(:deprecated => 'foo') }
          send_notification :deprecation_summary, null_notification

          expect(summary_stream.string).to match(/1 deprecation/)

          expected = <<-EOS.gsub(/^\s+\|/, '')
            |
            |Deprecation Warnings:
            |
            |foo is deprecated.
            |
            |#{DeprecationFormatter::RAISE_ERROR_CONFIG_NOTICE}
          EOS

          expect(deprecation_stream.string).to eq expected.chomp
        end
      end
    end
  end
end
