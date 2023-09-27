require_relative "function_name"

module Airfoil
  module Middleware
    class StepFunction < FunctionName
      def initialize(app, handler_class, *function_names_to_match, retried_exceptions: [])
        super(app, handler_class, *function_names_to_match)
        @retried_exceptions = retried_exceptions.map(&:to_s)
      end

      def call(env)
        context = env[:context]

        ignore_exceptions(context) do
          super
        end
      end

      def ignore_exceptions(context)
        disable_exceptions
        result = yield
        enable_exceptions

        result
      end

      def disable_exceptions
        @before = Sentry.configuration.excluded_exceptions
        Sentry.configuration.excluded_exceptions += @retried_exceptions
      end

      def enable_exceptions
        Sentry.configuration.excluded_exceptions = @before
      end
    end
  end
end
