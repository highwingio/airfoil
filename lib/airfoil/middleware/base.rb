module Airfoil
  module Middleware
    class Base
      def initialize(app)
        @app = app
      end
    end
  end
end
