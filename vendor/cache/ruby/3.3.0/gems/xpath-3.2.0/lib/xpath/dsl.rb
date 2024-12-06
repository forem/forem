# frozen_string_literal: true

module XPath
  module DSL
    def current
      Expression.new(:this_node)
    end

    def descendant(*expressions)
      Expression.new(:descendant, current, expressions)
    end

    def child(*expressions)
      Expression.new(:child, current, expressions)
    end

    def axis(name, *element_names)
      Expression.new(:axis, current, name, element_names)
    end

    def anywhere(*expressions)
      Expression.new(:anywhere, expressions)
    end

    def attr(expression)
      Expression.new(:attribute, current, expression)
    end

    def text
      Expression.new(:text, current)
    end

    def css(selector)
      Expression.new(:css, current, Literal.new(selector))
    end

    def function(name, *arguments)
      Expression.new(:function, name, *arguments)
    end

    def method(name, *arguments)
      Expression.new(:function, name, current, *arguments)
    end

    def where(expression)
      if expression
        Expression.new(:where, current, expression)
      else
        current
      end
    end
    alias_method :[], :where

    def is(expression)
      Expression.new(:is, current, expression)
    end

    def binary_operator(name, rhs)
      Expression.new(:binary_operator, name, current, rhs)
    end

    def union(*expressions)
      Union.new(*[self, expressions].flatten)
    end
    alias_method :+, :union

    def last
      function(:last)
    end

    def position
      function(:position)
    end

    METHODS = [
      # node set
      :count, :id, :local_name, :namespace_uri,
      # string
      :string, :concat, :starts_with, :contains, :substring_before,
      :substring_after, :substring, :string_length, :normalize_space,
      :translate,
      # boolean
      :boolean, :not, :true, :false, :lang,
      # number
      :number, :sum, :floor, :ceiling, :round
    ].freeze

    METHODS.each do |key|
      name = key.to_s.tr('_', '-').to_sym
      define_method key do |*args|
        method(name, *args)
      end
    end

    def qname
      method(:name)
    end

    alias_method :inverse, :not
    alias_method :~, :not
    alias_method :!, :not
    alias_method :normalize, :normalize_space
    alias_method :n, :normalize_space

    OPERATORS = [
      %i[equals = ==],
      %i[or or |],
      %i[and and &],
      %i[not_equals != !=],
      %i[lte <= <=],
      %i[lt < <],
      %i[gte >= >=],
      %i[gt > >],
      %i[plus +],
      %i[minus -],
      %i[multiply * *],
      %i[divide div /],
      %i[mod mod %]
    ].freeze

    OPERATORS.each do |(name, operator, alias_name)|
      define_method name do |rhs|
        binary_operator(operator, rhs)
      end
      alias_method alias_name, name if alias_name
    end

    AXES = %i[
      ancestor ancestor_or_self attribute descendant_or_self
      following following_sibling namespace parent preceding
      preceding_sibling self
    ].freeze

    AXES.each do |key|
      name = key.to_s.tr('_', '-').to_sym
      define_method key do |*element_names|
        axis(name, *element_names)
      end
    end

    alias_method :self_axis, :self

    def ends_with(suffix)
      function(:substring, current, function(:'string-length', current).minus(function(:'string-length', suffix)).plus(1)) == suffix
    end

    def contains_word(word)
      function(:concat, ' ', current.normalize_space, ' ').contains(" #{word} ")
    end

    UPPERCASE_LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞŸŽŠŒ'
    LOWERCASE_LETTERS = 'abcdefghijklmnopqrstuvwxyzàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿžšœ'

    def lowercase
      method(:translate, UPPERCASE_LETTERS, LOWERCASE_LETTERS)
    end

    def uppercase
      method(:translate, LOWERCASE_LETTERS, UPPERCASE_LETTERS)
    end

    def one_of(*expressions)
      expressions.map { |e| current.equals(e) }.reduce(:or)
    end

    def next_sibling(*expressions)
      axis(:"following-sibling")[1].axis(:self, *expressions)
    end

    def previous_sibling(*expressions)
      axis(:"preceding-sibling")[1].axis(:self, *expressions)
    end
  end
end
