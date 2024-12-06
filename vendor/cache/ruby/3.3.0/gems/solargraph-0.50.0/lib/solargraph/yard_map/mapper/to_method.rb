# frozen_string_literal: true

module Solargraph
  class YardMap
    class Mapper
      module ToMethod
        extend YardMap::Helpers

        def self.make code_object, name = nil, scope = nil, visibility = nil, closure = nil, spec = nil
          closure ||= Solargraph::Pin::Namespace.new(
            name: code_object.namespace.to_s,
            gates: [code_object.namespace.to_s]
          )
          location = object_location(code_object, spec)
          comments = code_object.docstring ? code_object.docstring.all.to_s : ''
          pin = Pin::Method.new(
            location: location,
            closure: closure,
            name: name || code_object.name.to_s,
            comments: comments,
            scope: scope || code_object.scope,
            visibility: visibility || code_object.visibility,
            # @todo Might need to convert overloads to signatures
            parameters: [],
            explicit: code_object.is_explicit?
          )
          pin.parameters.concat get_parameters(code_object, location, comments, pin)
          pin
        end

        class << self
          private

          # @param code_object [YARD::CodeObjects::Base]
          # @return [Array<Solargraph::Pin::Parameter>]
          def get_parameters code_object, location, comments, pin
            return [] unless code_object.is_a?(YARD::CodeObjects::MethodObject)
            # HACK: Skip `nil` and `self` parameters that are sometimes emitted
            # for methods defined in C
            # See https://github.com/castwide/solargraph/issues/345
            code_object.parameters.select { |a| a[0] && a[0] != 'self' }.map do |a|
              Solargraph::Pin::Parameter.new(
                location: location,
                closure: pin,
                comments: comments,
                name: arg_name(a),
                presence: nil,
                decl: arg_type(a),
                asgn_code: a[1]
              )
            end
          end

          # @param a [Array]
          # @return [String]
          def arg_name a
            a[0].gsub(/[^a-z0-9_]/i, '')
          end

          # @param a [Array]
          # @return [::Symbol]
          def arg_type a
            if a[0].start_with?('**')
              :kwrestarg
            elsif a[0].start_with?('*')
              :restarg
            elsif a[0].start_with?('&')
              :blockarg
            elsif a[0].end_with?(':')
              a[1] ? :kwoptarg : :kwarg
            elsif a[1]
              :optarg
            else
              :arg
            end
          end
        end
      end
    end
  end
end
