ENV['RACK_ENV'] ||= 'test'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'sidekiq'
require 'sidekiq-middleware-datadog'
require 'rails-middleware-datadog'
require 'datadog-client'

module Mock
  class Worker
    include Sidekiq::Worker
    def perform(name)
    end
  end

  class FakeUDPSocket
    attr_reader :buffer

    def initialize
      @buffer = []
    end
  
    def send(message, *)
      @buffer.push [message]
    end
  
    def recv
      @buffer.shift
    end
  
    def to_s
      inspect
    end
  
    def inspect
      "<FakeUDPSocket: #{@buffer.inspect}>"
    end
  end
end