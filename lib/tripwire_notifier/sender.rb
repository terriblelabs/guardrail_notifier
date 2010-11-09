module TripwireNotifier
  class Sender
    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def protocol
      self.configuration.secure? ? 'https' : 'http'
    end

    def port
      self.configuration.secure? ? 443 : 80
    end

    def host
      'api.tripwireapp.com'
    end

    def uri
      URI.parse("#{protocol}://#{host}:#{port}").merge('/')
    end

    def send_to_tripwire(data)
      uri = self.uri

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = self.configuration.timeout_in_seconds
      http.use_ssl      = self.configuration.secure?
      http.verify_mode  = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(data)

      begin
        response = http.request(request)
      rescue Exception => ex
        warn "Could not submit tripwireapp notification: #{ex.class} - #{ex.message}"
      end
    end
  end
end