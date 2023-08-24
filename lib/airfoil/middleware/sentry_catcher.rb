require "sentry-ruby"
require "airfoil/middleware/base"

module Airfoil
  module Middleware
    class SentryCatcher < Base
      def initialize(app, logger)
        super(app)
        @logger = logger
      end

      def call(env)
        @app.call(env)
      rescue => err
        Sentry.with_scope do |scope|
          context = env[:context]
          event = env[:event]

          scope.set_extras(
            function_name: context.function_name,
            function_version: context.function_version,
            invoked_function_arn: context.invoked_function_arn,
            memory_limit_in_mb: context.memory_limit_in_mb,
            aws_request_id: context.aws_request_id,
            log_group_name: context.log_group_name,
            log_stream_name: context.log_stream_name,
            identity: context.identity,
            event: event
          )

          Sentry.capture_exception(err)
          @logger.error(err)
          raise err
        end
      end
    end

    class RequestError < StandardError; end
  end
end
