# frozen_string_literal: true

require 'set'
module Rouge
  module Lexers
    load_lexer 'yaml.rb'

    class Digdag < YAML
      title 'digdag'
      desc 'A simple, open source, multi-cloud workflow engine (https://www.digdag.io/)'
      tag 'digdag'
      filenames '*.dig'

      mimetypes 'application/x-digdag'

      # http://docs.digdag.io/operators.html
      # as of digdag v0.9.10
      KEYWORD_PATTERN = Regexp.union(%w(
        call
        require
        loop
        for_each
        if
        fail
        echo

        td
        td_run
        td_ddl
        td_load
        td_for_each
        td_wait
        td_wait_table
        td_partial_delete
        td_table_export

        pg

        mail
        http
        s3_wait
        redshift
        redshift_load
        redshift_unload
        emr

        gcs_wait
        bq
        bq_ddl
        bq_extract
        bq_load

        sh
        py
        rb
        embulk
      ).map { |name| "#{name}>"} + %w(
        _do
        _parallel
      ))

      prepend :block_nodes do
        rule %r/(#{KEYWORD_PATTERN})(:)(?=\s|$)/ do |m|
          groups Keyword::Reserved, Punctuation::Indicator
          set_indent m[0], :implicit => true
        end
      end
    end
  end
end
