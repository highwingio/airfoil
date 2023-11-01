require "airfoil/middleware/base"

module Airfoil
  module Middleware
    class DatabaseConnection < Airfoil::Middleware::Base
      def call(env)
        # TODO: This explicitly makes a connection, which we may want to re-evaluate at some point
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.enable_query_cache!
          @app.call(env)
        ensure
          conn.disable_query_cache!
        end
      end
    end
  end
end
