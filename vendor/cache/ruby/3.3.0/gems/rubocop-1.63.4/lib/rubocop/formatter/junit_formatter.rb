# frozen_string_literal: true

require 'rexml/document'

#
# This code is based on https://github.com/mikian/rubocop-junit-formatter.
#
# Copyright (c) 2015 Mikko Kokkonen
#
# MIT License
#
# https://github.com/mikian/rubocop-junit-formatter/blob/master/LICENSE.txt
#
module RuboCop
  module Formatter
    # This formatter formats the report data in JUnit format.
    class JUnitFormatter < BaseFormatter
      def initialize(output, options = {})
        super

        @document = REXML::Document.new.tap { |document| document << REXML::XMLDecl.new }
        testsuites = REXML::Element.new('testsuites', @document)
        testsuite = REXML::Element.new('testsuite', testsuites)
        @testsuite = testsuite.tap { |element| element.add_attributes('name' => 'rubocop') }

        reset_count
      end

      def file_finished(file, offenses)
        @inspected_file_count += 1

        # TODO: Returns all cops with the same behavior as
        # the original rubocop-junit-formatter.
        # https://github.com/mikian/rubocop-junit-formatter/blob/v0.1.4/lib/rubocop/formatter/junit_formatter.rb#L9
        #
        # In the future, it would be preferable to return only enabled cops.
        Cop::Registry.all.each do |cop|
          target_offenses = offenses_for_cop(offenses, cop)
          @offense_count += target_offenses.count

          next unless relevant_for_output?(options, target_offenses)

          add_testcase_element_to_testsuite_element(file, target_offenses, cop)
        end
      end

      def relevant_for_output?(options, target_offenses)
        !options[:display_only_failed] || target_offenses.any?
      end

      def offenses_for_cop(all_offenses, cop)
        all_offenses.select { |offense| offense.cop_name == cop.cop_name }
      end

      def add_testcase_element_to_testsuite_element(file, target_offenses, cop)
        REXML::Element.new('testcase', @testsuite).tap do |testcase|
          testcase.attributes['classname'] = classname_attribute_value(file)
          testcase.attributes['name'] = cop.cop_name

          add_failure_to(testcase, target_offenses, cop.cop_name)
        end
      end

      def classname_attribute_value(file)
        @classname_attribute_value_cache ||= Hash.new do |hash, key|
          hash[key] = key.delete_suffix('.rb').gsub("#{Dir.pwd}/", '').tr('/', '.')
        end
        @classname_attribute_value_cache[file]
      end

      def finished(_inspected_files)
        @testsuite.add_attributes('tests' => @inspected_file_count, 'failures' => @offense_count)
        @document.write(output, 2)
      end

      private

      def reset_count
        @inspected_file_count = 0
        @offense_count = 0
      end

      def add_failure_to(testcase, offenses, cop_name)
        # One failure per offense. Zero failures is a passing test case,
        # for most surefire/nUnit parsers.
        offenses.each do |offense|
          REXML::Element.new('failure', testcase).tap do |failure|
            failure.attributes['type'] = cop_name
            failure.attributes['message'] = offense.message
            failure.add_text(offense.location.to_s)
          end
        end
      end
    end
  end
end
