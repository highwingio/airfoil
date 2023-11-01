require "airfoil/middleware/base"

module Airfoil
  module Middleware
    class LoggerTagging < Base
      def initialize(app, logger)
        super(app)
        @logger = logger
      end

      def call(env)
        context = env[:context]
        @logger.tagged(ENV["_X_AMZN_TRACE_ID"], context.aws_request_id) do
          @app.call(env)
        end
      end
    end
  end
end
