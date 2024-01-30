require "datadog/lambda"

module Airfoil
  class DatadogRailtie < Rails::Railtie
    config.datadog_enabled = ENV.fetch("DATADOG_ENABLED", Rails.env.production?).to_s == "true"

    initializer "airfoil.datadog" do
      if Rails.configuration.datadog_enabled
        require "ddtrace/auto_instrument"

        ::Datadog::Lambda.configure_apm do |c|
          c.env = ENV.fetch("SENTRY_ENVIRONMENT", Rails.env).dasherize
          # downscasing first ensures we don't attempt to snake case things that don't already have dashes
          c.service = (ENV["AWS_LAMBDA_FUNCTION_NAME"] || ENV["APP_NAME"] || "brokersuite").downcase.underscore

          # Set trace rate via DD_TRACE_SAMPLE_RATE
          c.tracing.enabled = true
          c.tracing.instrument :aws
          c.tracing.instrument :faraday
          c.tracing.instrument :rest_client
          c.tracing.instrument :httpclient
          c.tracing.instrument :http
          c.tracing.instrument :rails
        end

        Rails.logger.debug "=====DATADOG LOADED (RAILTIE)====="
      end
    end
  end
end
