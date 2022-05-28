require "airfoil/cloudwatch_formatter"

module Airfoil
  class Railtie < Rails::Railtie
    # Format logs for consistent parsing by Cloudwatch
    config.log_formatter = Airfoil::CloudwatchFormatter.new
  end
end
