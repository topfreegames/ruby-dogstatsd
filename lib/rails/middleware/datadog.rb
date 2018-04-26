module Rails
  module Middleware
    class Datadog      
      def initialize(app, opts={})
        @app = app

        statsd_host  = opts[:statsd_host] || "localhost"
        statsd_port  = opts[:statsd_port] || 8125
        namespace    = opts[:statsd_prefix] || nil

        @statsd = opts[:statsd] || Ruby::Reporters::Datadog.new(opts)
      end
    
      def call(env)
        start_request_time = Time.now
        status, header, body = @app.call(env)
        end_request_time = Time.now

        report_to_statsd(start_request_time, end_request_time, env, status)        

        [status, header, body]
      end

      private
      def extract_path_from_request(env)
        env['PATH_INFO']
      end

      def extract_method_from_request(env)
        env['REQUEST_METHOD']
      end

      def compute_elapsed_time_ms(start_request_time, end_request_time)
        (end_request_time - start_request_time) * 1000
      end

      def report_to_statsd(start_request_time, end_request_time, env, status)
        elapsed_time_ms = compute_elapsed_time_ms(start_request_time, end_request_time)
        request_method = extract_method_from_request(env)
        path = extract_path_from_request(env)

        @statsd.response_time_ms(path, request_method, status, elapsed_time_ms)
      end
    end
  end
end
