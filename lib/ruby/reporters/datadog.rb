require 'datadog/statsd'

module Ruby
  module Reporters
    class Datadog
      attr_reader :statsd, :response_time_metric_name, :default_http_tags
          
      def initialize(opts={})
        statsd_host                 = opts[:statsd_host] || "localhost"
        statsd_port                 = opts[:statsd_port] || 8125
        namespace                   = opts[:statsd_prefix] || nil
        
        @default_http_tags          = ['type:http']
        @response_time_metric_name  = 'response_time_ms'
        
        @statsd = opts[:statsd] || ::Datadog::Statsd.new(statsd_host, statsd_port, namespace: namespace)
      end
      
      def response_time_ms(path, method, status, value)
        tags = [
          "route:#{method.upcase} #{path}",
          "status:#{status}",
          "error:#{from_status_to_error(status)}"
        ]

        histogram(response_time_metric_name, value, default_http_tags | tags)
      end

      def gauge(metric_name, value, tags)
        statsd.gauge(
          metric_name,
          value,
          tags: tags
        )
      end

      def increment(metric_name, tags)
        statsd.increment(
          metric_name,
          tags: tags
        )
      end

      def histogram(metric_name, value, tags)
        statsd.histogram(
          metric_name,
          value,
          tags:tags
        )
      end

      def timing(metric_name, value, tags)
        statsd.timing(
          metric_name,
          value,
          tags:tags
        )
      end
    
      private
      def from_status_to_error(status)
        status.to_i < 400 ? "false" : "true"
      end
    end
  end
end
