require 'spec_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

describe Sidekiq::Middleware::Datadog do
  class Datadog::Statsd
    attr_accessor :socket
  end

  class Sidekiq::Middleware::Datadog
    def compute_elapsed_time_ms(start_time, end_time)
      21
    end
  end

  describe 'reports metrics to dd-statsd when middleware gets called' do  
    before(:all)  do
      @statsd = Datadog::Statsd.new("localhost", 8125)
      @statsd.socket = Mock::FakeUDPSocket.new

      Sidekiq::Testing.server_middleware do |chain|
        chain.add Sidekiq::Middleware::Datadog, hostname: "localhost", statsd: @statsd, tags: ["custom:tag", lambda{|w, *| "worker:0" }] 
      end
    end

    context 'enqueueing all two jobs' do
      let(:worker) { Mock::Worker.new }

      before(:context) do
        @jobs = ['test-job-1', 'test-job-2']
        @jobs.each { | job | Mock::Worker.perform_async(job) }
      end

      it 'should have two jobs at the queue' do
        expect(Sidekiq::Queues["default"].size).to eq(@jobs.size)
      end

      context 'middleware gets called' do
        before(:all) do
          Mock::Worker.drain  
        end

        it 'should have 0 jobs at the queue' do
          expect(Sidekiq::Queues["default"].size).to eq(0)        
        end

        it 'should publish metrics from the fisrt job to dogstatd' do
          expect(@statsd.socket.buffer[0]).to eq([
            "worker.run_time_ms:21|ms|#custom:tag,worker:0,env:test,name:mock/worker,queue:default,error:false"
          ])

          expect(@statsd.socket.buffer[1]).to eq([
            "worker.queue_size:1|g|#custom:tag,worker:0,env:test,name:mock/worker,queue:default,error:false"
          ])
        end

        it 'should publish metrics from the second job to dogstatd' do
          expect(@statsd.socket.buffer[0]).to eq([
            "worker.run_time_ms:21|ms|#custom:tag,worker:0,env:test,name:mock/worker,queue:default,error:false"
          ])

          expect(@statsd.socket.buffer[1]).to eq([
            "worker.queue_size:1|g|#custom:tag,worker:0,env:test,name:mock/worker,queue:default,error:false"
          ])
        end
      end
    end
  end
end