require 'datadog/statsd'
require 'socket'
require 'sidekiq'

module Sidekiq
  module Middleware
    class Datadog
      attr_accessor :hostname, :statsd_host, :statsd_port, :statsd, :xalala 
      # Configure and install datadog instrumentation. Example:
      #
      #   Sidekiq.configure_server do |config|
      #     config.server_middleware do |chain|
      #       chain.add Sidekiq::Middleware::Datadog
      #     end
      #   end
      #
      
      def initialize(opts)
        statsd_host   = opts[:statsd_host] || "localhost"
        statsd_port   = (opts[:statsd_port] || 8125).to_i
        prefix        = opts[:prefix] || ""
        
        @metric_name  = opts[:metric_name] || "worker"
        @statsd       = opts[:statsd] || ::Datadog::Statsd.new(statsd_host, statsd_port, namespace: prefix)
        @tags         = opts[:tags] || []

        enrich_global_tags()
      end

      def call(worker, job, queue, *)
        start = Time.now
        
        begin
          yield
          record(worker, job, queue, start)
        rescue => e
          record(worker, job, queue, start, e)
          raise
        end
      end

      private
      def enrich_global_tags
        env = Sidekiq.options[:environment] || ENV['RACK_ENV']

        if env && @tags.none? {|t| t =~ /^env\:/ }
          @tags.push("env:#{ENV['RACK_ENV']}")
        end
      end

      def pre_proccess_tags(tags, worker, job, name, queue, error)
        tags = @tags.map do |tag|
          case tag 
          when String 
            then tag 
          when Proc 
            then tag.call(worker, job, queue, error) 
          end
        end

        tags.push "name:#{name}"
        tags.push "queue:#{queue}" if queue 

        if error
          kind = replace_hifen_to_underscore(error.class.name.sub(/Error$/, ''))
          tags.push "error:true", "error_kind:#{kind}"
        else
            tags.push "error:false"
        end
       
        tags.compact
      end


      def record(worker, job, queue, start, error = nil)
        end_time = Time.now

        elapsed_time_ms   = compute_elapsed_time_ms(end_time, start)
        name = replace_hifen_to_underscore(job['wrapped'] || worker.class.to_s)
        tags = pre_proccess_tags(@tags, worker, job, name, queue, error)
        
        report_queue_processing_time(elapsed_time_ms, tags)
        report_queue_length(queue, tags)
      end

      def replace_hifen_to_underscore(word)
        word = word.to_s.gsub(/::/, '/')
        word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        word.tr!("-", "_")

        word.downcase
      end

      def compute_elapsed_time_ms(start_time, end_time)
        (end_time - start_time) * 1000
      end

      def report_queue_length(queue_name, tags)
        queue = queue_name ? Sidekiq::Queues[queue_name] : Sidekiq::Queues["default"]
        @statsd.gauge "#{@metric_name}.queue_size", queue.size, :tags => tags
      end

      def report_queue_processing_time(value, tags)
        @statsd.timing "#{@metric_name}.run_time_ms", value, :tags => tags
      end
    end
  end
end