require 'net/http'
require 'net/https'
require 'uri'
require 'tripwire_notifier/version'
require 'tripwire_notifier/configuration'
require 'tripwire_notifier/sender'
require 'tripwire_notifier/rails/action_controller_monitor'

module TripwireNotifier
  API_VERSION = "alpha 1"

  class << self
    attr_accessor :configuration
    attr_accessor :sender

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(self.configuration)
      self.sender = Sender.new(self.configuration)
    end

    def notify(data)
      self.sender.send_to_tripwire(data.merge(notifier_params))
    end

    def notifier_params
      {}.tap do |params|
        params[:notifier_version] = self.configuration.notifier_version
        params[:api_key]          = self.configuration.api_key || ENV['TRIPWIRE_API_KEY']
        params[:api_version]      = API_VERSION
      end
    end
  end
end
