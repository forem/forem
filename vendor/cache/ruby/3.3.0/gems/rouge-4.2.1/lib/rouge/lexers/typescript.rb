# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'javascript.rb'
    load_lexer 'typescript/common.rb'

    class Typescript < Javascript
      extend TypescriptCommon

      title "TypeScript"
      desc "TypeScript, a superset of JavaScript (https://www.typescriptlang.org/)"

      tag 'typescript'
      aliases 'ts'

      filenames '*.ts', '*.d.ts', '*.cts', '*.mts'

      mimetypes 'text/typescript'
    end
  end
end
