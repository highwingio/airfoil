require_relative "middleware/datadog"
require_relative "datadog_railtie" if defined?(Rails::Railtie)
