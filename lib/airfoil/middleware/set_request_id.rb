require "airfoil/middleware/base"

module Airfoil
  module Middleware
    class SetRequestId < Base
      def call(env)
        context = env[:context]
        ENV["AWS_REQUEST_ID"] = context.aws_request_id if context.present?
        @app.call(env)
      end
    end
  end
end
