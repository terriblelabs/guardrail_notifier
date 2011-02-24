module TripwireNotifier
  class Configuration
    attr_accessor :api_key

    # The set of environments that should be monitored for validation errors (defaults to
    # only the production environment).
    attr_accessor :monitored_environments

    # Number of seconds after which submission to Tripwire should timeout (defaults to 5).
    attr_accessor :timeout_in_seconds

    # +true+ for https connections, +false+ for http connections.
    attr_accessor :secure
    alias_method :secure?, :secure

    # A +call+able object, such as a Proc, to be invoked if an exception occurs when
    # logging to Tripwire (defaults to nil). For example, to notify Hoptoad:
    #
    #   config.on_exception = proc { |e| notify_hoptoad(e) }
    attr_accessor :on_exception

    # The version of the notifier (defaults to the version of this gem).
    attr_reader :notifier_version

    def initialize
      @notifier_version = VERSION
      @timeout_in_seconds = 5
      @monitored_environments = ['production']
      @secure = false
      @on_exception = nil
    end
  end
end