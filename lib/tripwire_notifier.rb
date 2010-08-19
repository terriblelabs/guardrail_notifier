require 'net/http'
require 'uri'
require 'timeout'
require 'tripwire_notifier/version'
require 'tripwire_notifier/configuration'
require 'tripwire_notifier/rails/action_controller_monitor'

module TripwireNotifier
  API_VERSION = "alpha 1"
  API_URL     = 'http://api.tripwireapp.com/'

  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end
  end
end
