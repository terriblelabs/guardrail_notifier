require 'helper'

class SenderTest < Test::Unit::TestCase
  def setup
    GuardrailNotifier.configure do |c|
      c.api_key = 'API_KEY'
    end
    @sender = GuardrailNotifier::Sender.new(GuardrailNotifier.configuration)
  end

  context "initialize" do
    should "set configuration" do
      assert_same GuardrailNotifier.configuration, @sender.configuration
      assert_equal 'API_KEY', @sender.configuration.api_key
    end
  end

  context "when not configured to be secure" do
    setup do
      GuardrailNotifier.configuration.secure = false
    end

    should "return 'http' for #protocol" do
      assert_equal 'http', @sender.protocol
    end

    should "return 80 for #port" do
      assert_equal 80, @sender.port
    end

    should "post data without ssl on insecure port" do
      assert_sends_to_guardrail(false, 80)
    end
  end

  context "when configured to be secure" do
    setup do
      GuardrailNotifier.configuration.secure = true
    end

    should "return 'https' for protocol" do
      assert_equal 'https', @sender.protocol
    end

    should "return 443 for #port" do
      assert_equal 443, @sender.port
    end

    should "post data with ssl on secure port" do
      assert_sends_to_guardrail(true, 443)
    end
  end

  should "return api.guardrailapp.com for #host" do
    assert_equal 'api.guardrailapp.com', @sender.host
  end


  def assert_sends_to_guardrail(use_ssl, port)
    data = {:key => :value}

    mock_request = mock()
    mock_request.expects(:set_form_data).with(data)
    Net::HTTP::Post.stubs(:new => mock_request)

    mock_http = mock()
    mock_http.expects(:open_timeout=)
    mock_http.expects(:use_ssl=).with(use_ssl)
    mock_http.expects(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
    mock_http.expects(:request).with(mock_request)
    Net::HTTP.stubs(:new => mock_http)

    @sender.send_to_guardrail(data)
  end
end
