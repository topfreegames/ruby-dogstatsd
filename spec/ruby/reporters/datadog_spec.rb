require 'spec_helper'
require 'sidekiq/testing'

describe Ruby::Reporters::Datadog do
  class Datadog::Statsd
    attr_accessor :socket
  end

  describe 'report metrics to dd-statsd' do  
    context 'using default values for host and port' do
      before(:all) do
        @statsd = Ruby::Reporters::Datadog.new(namespace: "dd_statsd_test")
        @statsd.statsd.socket = Mock::FakeUDPSocket.new
      end

      before(:each) do
        @statsd.statsd.socket.buffer.clear()
      end

      context 'exploring response_time_ms' do
        context 'request failed, returning 404' do
          it 'should report a response_time_ms with tag error:true' do
            @statsd.response_time_ms("/root", "get", 404, 1230)

            expect(@statsd.statsd.socket.buffer).to eq([[
              "response_time_ms:1230|h|#type:http,route:GET /root,status:404,error:true"
              ]])
          end
        end

        context 'request failed, returning 503' do
          it 'should report a response_time_ms with tag error:true' do
            @statsd.response_time_ms("/root", "get", 503, 1230)

            expect(@statsd.statsd.socket.buffer).to eq([[
              "response_time_ms:1230|h|#type:http,route:GET /root,status:503,error:true"
              ]])
          end
        end

        context 'request succeeded, returning 200' do
          it 'should report a response_time_ms with tag error:false' do
            @statsd.response_time_ms("/root", "get", 200, 1230)

            expect(@statsd.statsd.socket.buffer).to eq([[
              "response_time_ms:1230|h|#type:http,route:GET /root,status:200,error:false"
              ]])
          end
        end
      end

      context 'exploring native calls' do
        it 'should report a gauge' do
          @statsd.gauge("number-of-pitayas", 342, ['status:ready-for-consumption'])

          expect(@statsd.statsd.socket.buffer).to eq([[
            "number-of-pitayas:342|g|#status:ready-for-consumption"
            ]])
        end

        it 'should increment a counter' do
          @statsd.increment("number-of-pitayas", ['kind:juice'])

          expect(@statsd.statsd.socket.buffer).to eq([[
            "number-of-pitayas:1|c|#kind:juice"
            ]])
        end
      end
    end
  end
end