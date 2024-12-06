# frozen_string_literal: true

require "singleton"

module Ferrum
  class CyclicObject
    include Singleton

    def inspect
      %(#<#{self.class} JavaScript object that cannot be represented in Ruby>)
    end
  end

  class Frame
    module Runtime
      INTERMITTENT_ATTEMPTS = ENV.fetch("FERRUM_INTERMITTENT_ATTEMPTS", 6).to_i
      INTERMITTENT_SLEEP = ENV.fetch("FERRUM_INTERMITTENT_SLEEP", 0.1).to_f

      #
      # Evaluate and return result for given JS expression.
      #
      # @param [String] expression
      #   The JavaScript to evaluate.
      #
      # @param [Array] args
      #   Additional arguments to pass to the JavaScript code.
      #
      # @example
      #   browser.evaluate("[window.scrollX, window.scrollY]")
      #
      def evaluate(expression, *args)
        expression = format("function() { return %s }", expression)
        call(expression: expression, arguments: args)
      end

      #
      # Evaluate asynchronous expression and return result.
      #
      # @param [String] expression
      #   The JavaScript to evaluate.
      #
      # @param [Integer] wait
      #   How long we should wait for Promise to resolve or reject.
      #
      # @param [Array] args
      #   Additional arguments to pass to the JavaScript code.
      #
      # @example
      #   browser.evaluate_async(%(arguments[0]({foo: "bar"})), 5) # => { "foo" => "bar" }
      #
      def evaluate_async(expression, wait, *args)
        template = <<~JS
          function() {
            return new Promise((__f, __r) => {
              try {
                arguments[arguments.length] = r => __f(r);
                arguments.length = arguments.length + 1;
                setTimeout(() => __r(new Error("timed out promise")), %s);
                %s
              } catch(error) {
                __r(error);
              }
            });
          }
        JS

        expression = format(template, wait * 1000, expression)
        call(expression: expression, arguments: args, awaitPromise: true)
      end

      #
      # Execute expression. Doesn't return the result.
      #
      # @param [String] expression
      #   The JavaScript to evaluate.
      #
      # @param [Array] args
      #   Additional arguments to pass to the JavaScript code.
      #
      # @example
      #   browser.execute(%(1 + 1)) # => true
      #
      def execute(expression, *args)
        expression = format("function() { %s }", expression)
        call(expression: expression, arguments: args, handle: false, returnByValue: true)
        true
      end

      def evaluate_func(expression, *args, on: nil)
        call(expression: expression, arguments: args, on: on)
      end

      def evaluate_on(node:, expression:, by_value: true, wait: 0)
        options = { handle: true }
        expression = format("function() { return %s }", expression)
        options = { handle: false, returnByValue: true } if by_value
        call(expression: expression, on: node, wait: wait, **options)
      end

      private

      def call(expression:, arguments: [], on: nil, wait: 0, handle: true, **options)
        errors = [NodeNotFoundError, NoExecutionContextError]

        Utils::Attempt.with_retry(errors: errors, max: INTERMITTENT_ATTEMPTS, wait: INTERMITTENT_SLEEP) do
          params = options.dup

          if on
            response = @page.command("DOM.resolveNode", nodeId: on.node_id)
            object_id = response.dig("object", "objectId")
            params = params.merge(objectId: object_id)
          end

          if params[:executionContextId].nil? && params[:objectId].nil?
            params = params.merge(executionContextId: execution_id!)
          end

          response = @page.command("Runtime.callFunctionOn",
                                   wait: wait, slowmoable: true,
                                   **params.merge(functionDeclaration: expression,
                                                  arguments: prepare_args(arguments)))
          handle_error(response)
          response = response["result"]

          handle ? handle_response(response) : response["value"]
        end
      end

      # FIXME: We should have a central place to handle all type of errors
      def handle_error(response)
        result = response["result"]
        return if result["subtype"] != "error"

        case result["description"]
        when /\AError: timed out promise/
          raise ScriptTimeoutError
        else
          raise JavaScriptError.new(result, response.dig("exceptionDetails", "stackTrace"))
        end
      end

      def handle_response(response)
        case response["type"]
        when "boolean", "number", "string"
          response["value"]
        when "undefined"
          nil
        when "function"
          {}
        when "object"
          object_id = response["objectId"]

          case response["subtype"]
          when "node"
            # We cannot store object_id in the node because page can be reloaded
            # and node destroyed so we need to retrieve it each time for given id.
            # Though we can try to subscribe to `DOM.childNodeRemoved` and
            # `DOM.childNodeInserted` in the future.
            node_id = @page.command("DOM.requestNode", objectId: object_id)["nodeId"]
            description = @page.command("DOM.describeNode", nodeId: node_id)["node"]
            Node.new(self, @page.target_id, node_id, description)
          when "array"
            reduce_props(object_id, []) do |memo, key, value|
              next(memo) unless Integer(key, exception: false)

              value = value["objectId"] ? handle_response(value) : value["value"]
              memo.insert(key.to_i, value)
            end.compact
          when "date"
            response["description"]
          when "null"
            nil
          else
            reduce_props(object_id, {}) do |memo, key, value|
              value = value["objectId"] ? handle_response(value) : value["value"]
              memo.merge(key => value)
            end
          end
        end
      end

      def prepare_args(args)
        args.map do |arg|
          if arg.is_a?(Node)
            resolved = @page.command("DOM.resolveNode", nodeId: arg.node_id)
            { objectId: resolved["object"]["objectId"] }
          elsif arg.is_a?(Hash) && arg["objectId"]
            { objectId: arg["objectId"] }
          else
            { value: arg }
          end
        end
      end

      def reduce_props(object_id, to)
        if cyclic?(object_id).dig("result", "value")
          to.is_a?(Array) ? [cyclic_object] : cyclic_object
        else
          props = @page.command("Runtime.getProperties", ownProperties: true, objectId: object_id)
          props["result"].reduce(to) do |memo, prop|
            next(memo) unless prop["enumerable"]

            yield(memo, prop["name"], prop["value"])
          end
        end
      end

      def cyclic?(object_id)
        @page.command(
          "Runtime.callFunctionOn",
          objectId: object_id,
          returnByValue: true,
          functionDeclaration: <<~JS
            function() {
              if (Array.isArray(this) &&
                  this.every(e => e instanceof Node)) {
                return false;
              }

              function detectCycle(obj, seen) {
                if (typeof obj === "object") {
                  if (seen.indexOf(obj) !== -1) {
                    return true;
                  }
                  for (let key in obj) {
                    if (obj.hasOwnProperty(key) && detectCycle(obj[key], seen.concat([obj]))) {
                      return true;
                    }
                  }
                }

                return false;
              }

              return detectCycle(this, []);
            }
          JS
        )
      end

      def cyclic_object
        CyclicObject.instance
      end
    end
  end
end
