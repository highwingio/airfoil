require "sentry-ruby"
require "airfoil/middleware/base"

module Airfoil
  module Middleware
    class SentryMonitoring < Base
      def call(env)
        context = env[:context]
        event = env[:event]

        sentry_trace_id = get_first_instance(event, "sentry_trace_id")
        identity = get_first_instance(event, "identity")

        options = {name: context.function_name, op: "handler"}
        options[:transaction] = Sentry::Transaction.from_sentry_trace(sentry_trace_id, **options) if sentry_trace_id.present?

        Sentry.set_user(username: identity.dig("username"), ip_address: identity.dig("source_ip", 0)) if identity.present?
        transaction = Sentry.start_transaction(**options)
        # Add transaction to the global scope so it is accessible throughout the app
        Sentry.get_current_hub&.configure_scope do |scope|
          scope.set_span(transaction)
        end

        result = @app.call(env)
        transaction.finish if transaction.present?

        result
      end

      private

      def get_first_instance(event, key)
        case event
        in [e, *rest]
          e.dig(key)
        in Hash
          event.dig(key)
        else
          nil
        end
      end
    end
  end
end
