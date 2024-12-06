# frozen_string_literal: true

module Solargraph
  class TypeChecker
    # Helper methods for performing type checks
    #
    module Checks
      module_function

      # Compare an expected type with an inferred type. Common usage is to
      # check if the type declared in a method's @return tag matches the type
      # inferred from static analysis of the code.
      #
      # @param api_map [ApiMap]
      # @param expected [ComplexType]
      # @param inferred [ComplexType]
      # @return [Boolean]
      def types_match? api_map, expected, inferred
        return true if expected.to_s == inferred.to_s
        matches = []
        expected.each do |exp|
          found = false
          inferred.each do |inf|
            # if api_map.super_and_sub?(fuzz(inf), fuzz(exp))
            if either_way?(api_map, inf, exp)
              found = true
              matches.push inf
              break
            end
          end
          return false unless found
        end
        inferred.each do |inf|
          next if matches.include?(inf)
          found = false
          expected.each do |exp|
            # if api_map.super_and_sub?(fuzz(inf), fuzz(exp))
            if either_way?(api_map, inf, exp)
              found = true
              break
            end
          end
          return false unless found
        end
        true
      end

      # @param api_map [ApiMap]
      # @param expected [ComplexType]
      # @param inferred [ComplexType]
      # @return [Boolean]
      def any_types_match? api_map, expected, inferred
        return duck_types_match?(api_map, expected, inferred) if expected.duck_type?
        expected.each do |exp|
          next if exp.duck_type?
          inferred.each do |inf|
            # return true if exp == inf || api_map.super_and_sub?(fuzz(inf), fuzz(exp))
            return true if exp == inf || either_way?(api_map, inf, exp)
          end
        end
        false
      end

      # @param api_map [ApiMap]
      # @param inferred [ComplexType]
      # @param expected [ComplexType]
      # @return [Boolean]
      def all_types_match? api_map, inferred, expected
        return duck_types_match?(api_map, expected, inferred) if expected.duck_type?
        inferred.each do |inf|
          next if inf.duck_type?
          return false unless expected.any? { |exp| exp == inf || either_way?(api_map, inf, exp) }
        end
        true
      end

      # @param api_map [ApiMap]
      # @param expected [ComplexType]
      # @param inferred [ComplexType]
      # @return [Boolean]
      def duck_types_match? api_map, expected, inferred
        raise ArgumentError, 'Expected type must be duck type' unless expected.duck_type?
        expected.each do |exp|
          next unless exp.duck_type?
          quack = exp.to_s[1..-1]
          return false if api_map.get_method_stack(inferred.namespace, quack, scope: inferred.scope).empty?
        end
        true
      end

      # @param type [ComplexType::UniqueType]
      # @return [String]
      def fuzz type
        if type.parameters?
          type.name
        else
          type.tag
        end
      end

      # @param api_map [ApiMap]
      # @param cls1 [ComplexType::UniqueType]
      # @param cls2 [ComplexType::UniqueType]
      # @return [Boolean]
      def either_way?(api_map, cls1, cls2)
        f1 = fuzz(cls1)
        f2 = fuzz(cls2)
        api_map.type_include?(f1, f2) || api_map.super_and_sub?(f1, f2) || api_map.super_and_sub?(f2, f1)
      end
    end
  end
end
