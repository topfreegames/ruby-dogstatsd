require "rails/middleware/datadog"

module Sinatra
  module Middleware
    class Datadog < Rails::Middleware::Datadog
    end
  end
end
