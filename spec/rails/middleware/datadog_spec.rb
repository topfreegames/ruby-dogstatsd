require 'spec_helper'
require 'sidekiq/testing'
require 'rack'

describe Rails::Middleware::Datadog do
  class Datadog::Statsd
    attr_accessor :socket
  end

  class Rails::Middleware::Datadog
    def compute_elapsed_time_ms(start_request_time, end_request_time)
      10
    end
  end

  describe 'teste reporting pre-defined metrics' do  
    context 'using rails middleware with dafault statsd host and port' do
      before(:all) do
        @statsd = Ruby::Reporters::Datadog.new(namespace: "dd_statsd_test")
        @statsd.statsd.socket = Mock::FakeUDPSocket.new
      end

      before(:each) do
        @statsd.statsd.socket.buffer.clear()
      end
      
      context 'successful request' do
        let(:app) { lambda {|env| [200, {'Content-Type' => 'text/plain'}, ['OK']]} }
        let(:middleware) { Rails::Middleware::Datadog.new(app, {statsd: @statsd})  }

        it 'should report a response_time_ms with tag error:false and other tags' do
          middleware.call env_for('http://sniper3d.tfgco.com/players')

          expect(@statsd.statsd.socket.buffer).to eq([[
            "response_time_ms:10|h|#type:http,route:GET /players,status:200,error:false"
            ]])
        end
      end

      context 'failed, returning 404' do
        let(:app) { lambda {|env| [404, {'Content-Type' => 'text/plain'}, ['Not Found']]} }
        let(:middleware) { Rails::Middleware::Datadog.new(app, {statsd: @statsd})  }

        it 'should report a response_time_ms with tag error:false and other tags' do
          middleware.call env_for('http://sniper3d.tfgco.com/players/xablau')

          expect(@statsd.statsd.socket.buffer).to eq([[
            "response_time_ms:10|h|#type:http,route:GET /players/xablau,status:404,error:true"
            ]])
        end
      end

      context 'failed, returning 503' do
        let(:app) { lambda {|env| [503, {'Content-Type' => 'text/plain'}, ['Internal Server Error']]} }
        let(:middleware) { Rails::Middleware::Datadog.new(app, {statsd: @statsd})  }

        it 'should report a response_time_ms with tag error:false and other tags' do
          middleware.call env_for('http://sniper3d.tfgco.com/players/xablau')

          expect(@statsd.statsd.socket.buffer).to eq([[
            "response_time_ms:10|h|#type:http,route:GET /players/xablau,status:503,error:true"
            ]])
        end
      end
    end
  end

  def env_for(url, opts={})
    Rack::MockRequest.env_for(url, opts)
  end
end