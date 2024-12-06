# frozen_string_literal: true

require "rexml/document"
require "rexml/formatters/pretty"

module ERBLint
  module Reporters
    class JunitReporter < Reporter
      def preview; end

      def show
        xml = create_junit_xml
        formatted_xml_string = StringIO.new
        REXML::Formatters::Pretty.new.write(xml, formatted_xml_string)
        puts formatted_xml_string.string
      end

      private

      CONTEXT = {
        prologue_quote: :quote,
        attribute_quote: :quote,
      }

      def create_junit_xml
        # create prologue
        xml = REXML::Document.new(nil, CONTEXT)
        xml << REXML::XMLDecl.new("1.0", "UTF-8")

        xml.add_element(create_testsuite_element)

        xml
      end

      def create_testsuite_element
        tests = stats.processed_files.size
        failures = stats.found
        testsuite_element = REXML::Element.new("testsuite", nil, CONTEXT)
        testsuite_element.add_attribute("name", "erblint")
        testsuite_element.add_attribute("tests", tests.to_s)
        testsuite_element.add_attribute("failures", failures.to_s)

        testsuite_element.add_element(create_properties)

        processed_files.each do |filename, offenses|
          if offenses.empty?
            testcase_element = REXML::Element.new("testcase", nil, CONTEXT)
            testcase_element.add_attribute("name", filename.to_s)
            testcase_element.add_attribute("file", filename.to_s)

            testsuite_element.add_element(testcase_element)
          end

          offenses.each do |offense|
            testsuite_element.add_element(create_testcase(filename, offense))
          end
        end

        testsuite_element
      end

      def create_properties
        properties_element = REXML::Element.new("properties", nil, CONTEXT)

        [
          ["erb_lint_version", ERBLint::VERSION],
          ["ruby_engine", RUBY_ENGINE],
          ["ruby_version", RUBY_VERSION],
          ["ruby_patchlevel", RUBY_PATCHLEVEL.to_s],
          ["ruby_platform", RUBY_PLATFORM],
        ].each do |property_attribute|
          properties_element.add_element(create_property(*property_attribute))
        end

        properties_element
      end

      def create_property(name, value)
        property_element = REXML::Element.new("property")
        property_element.add_attribute("name", name)
        property_element.add_attribute("value", value)

        property_element
      end

      def create_testcase(filename, offense)
        testcase_element = REXML::Element.new("testcase", nil, CONTEXT)
        testcase_element.add_attribute("name", filename.to_s)
        testcase_element.add_attribute("file", filename.to_s)
        testcase_element.add_attribute("lineno", offense.line_number.to_s)

        testcase_element.add_element(create_failure(filename, offense))

        testcase_element
      end

      def create_failure(filename, offense)
        message = offense.message
        type = offense.simple_name

        failure_element = REXML::Element.new("failure", nil, CONTEXT)
        failure_element.add_attribute("message", "#{type}: #{message}")
        failure_element.add_attribute("type", type.to_s)

        cdata_element = REXML::CData.new("#{type}: #{message} at #{filename}:#{offense.line_number}:#{offense.column}")
        failure_element.add_text(cdata_element)

        failure_element
      end
    end
  end
end
