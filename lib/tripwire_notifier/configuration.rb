module TripwireNotifier
  class Configuration
    attr_accessor :notifier_version
    attr_accessor :api_key
    attr_accessor :monitored_environments
    attr_accessor :timeout_in_seconds

    def initialize
      @notifier_version = VERSION
      @timeout_in_seconds = 5
      @monitored_environments = ['production']
    end
  end
end