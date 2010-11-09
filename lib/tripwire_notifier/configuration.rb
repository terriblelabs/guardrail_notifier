module TripwireNotifier
  class Configuration
    attr_reader :notifier_version
    attr_accessor :api_key
    attr_accessor :monitored_environments
    attr_accessor :timeout_in_seconds
    attr_accessor :secure

    alias_method :secure?, :secure

    def initialize
      @notifier_version = VERSION
      @timeout_in_seconds = 5
      @monitored_environments = ['production']
      @secure = false
    end
  end
end