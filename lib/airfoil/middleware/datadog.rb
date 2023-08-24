require "datadog/lambda"
require "datadog/tracing"
require "airfoil/middleware/base"

module Airfoil
  module Middleware
    class Datadog < Base
      # See the Airfoil railtie for config loaded at Rails load-time
      # Note: Rails loads prior to Airfoil because of the inclusion of `require_relative "config/environment"`
      # in the engine lambda handler
      def call(env)
        event, context = env.values_at(:event, :context)

        ::Datadog::Lambda.wrap(event, context) do
          @app.call(env)
        rescue => err
          ::Datadog::Tracing.active_span&.set_error(err)
          raise err
        end
      end
    end
  end
end
