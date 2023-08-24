require "airfoil/middleware/base"

module Airfoil
  module Middleware
    class FunctionName < Middleware::Base
      def initialize(app, handler_class, *function_names_to_match)
        super(app)
        @handler_class = handler_class
        @function_names_to_match = function_names_to_match
      end

      def call(env)
        context = env[:context]

        if handles? context
          @handler_class.handle(env[:event], context)
        else
          @app.call(env)
        end
      end

      private

      def handles?(context)
        @function_names_to_match.include?(canonicalize_function_name(context.function_name))
      end

      # Strip off the function suffix if present to allow for terraform/terratest to invoke lambdas with unique names that route to the same function
      # e.g. finalize-submission-testrun89YD36 => finalize-submission
      def canonicalize_function_name(function_name)
        function_name.sub(/-testrun[a-zA-Z0-9]*$/, "")
      end
    end
  end
end
