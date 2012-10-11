require 'net/http'
require 'net/https'
require 'uri'
require 'guardrail_notifier/version'
require 'guardrail_notifier/configuration'
require 'guardrail_notifier/sender'
require 'guardrail_notifier/rails/action_controller_monitor'

module GuardrailNotifier
  API_VERSION = "alpha 1"

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(self.configuration)
    end

    def sender
      @sender ||= Sender.new(self.configuration)
    end

    def notify(data)
      self.sender.send_to_guardrail(data.merge(notifier_params))
    end

    def notifier_params
      @notifier_params ||= {
        :notifier_version => self.configuration.notifier_version,
        :api_key          => self.configuration.api_key || ENV['GUARDRAIL_API_KEY'],
        :api_version      => API_VERSION
      }
    end
  end
end
