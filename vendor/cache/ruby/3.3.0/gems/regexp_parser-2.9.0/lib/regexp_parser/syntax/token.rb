# Define the base module and the simplest of tokens.
module Regexp::Syntax
  module Token
    Map = {}

    module Literal
      All = %i[literal]
      Type = :literal
    end

    module FreeSpace
      All  = %i[comment whitespace]
      Type = :free_space
    end

    Map[FreeSpace::Type] = FreeSpace::All
    Map[Literal::Type]   = Literal::All
  end
end


# Load all the token files, they will populate the Map constant.
require 'regexp_parser/syntax/token/anchor'
require 'regexp_parser/syntax/token/assertion'
require 'regexp_parser/syntax/token/backreference'
require 'regexp_parser/syntax/token/posix_class'
require 'regexp_parser/syntax/token/character_set'
require 'regexp_parser/syntax/token/character_type'
require 'regexp_parser/syntax/token/conditional'
require 'regexp_parser/syntax/token/escape'
require 'regexp_parser/syntax/token/group'
require 'regexp_parser/syntax/token/keep'
require 'regexp_parser/syntax/token/meta'
require 'regexp_parser/syntax/token/quantifier'
require 'regexp_parser/syntax/token/unicode_property'


# After loading all the tokens the map is full. Extract all tokens and types
# into the All and Types constants.
module Regexp::Syntax
  module Token
    All   = Map.values.flatten.uniq.sort.freeze
    Types = Map.keys.freeze
  end
end
