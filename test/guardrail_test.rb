require 'helper'

class TestGuardrail < Test::Unit::TestCase
  def fake_controller(klass)
    fake = klass.new
    fake.params = {'action' => "foo", 'controller' => "bar"}
    fake.request = OpenStruct.new(
      :user_agent => 'FooFox',
      :cookies => {'one' => 'two', 'three' => 'four'},
      :session => {'something' => 'ok', 'some_class' => String, 'some_number' => 42, :some_array => [Date, 24]}
    )
    fake
  end

  def setup
    Rails.stubs(:env => 'production')

    @foo_controller = fake_controller(FooController)

    FakeWeb.register_uri(:post, 'http://api.guardrailapp.com', :body => "")

    GuardrailNotifier.configure do |config|
      config.api_key = "SOME API KEY"
      config.monitored_environments = ['production']
    end

    @model_one   = OpenStruct.new(:errors => {"bar" => "is blank"})
    @model_two   = OpenStruct.new(:errors => {"baz" => "is blank"})
    @model_three = OpenStruct.new(:errors => {"f1" => "is blank","f2" => ["is too large", "is delicious"]})

    @foo_controller.instance_variable_set("@lol", @model_one)
    @foo_controller.instance_variable_set("@wtf", [@model_two, @model_three])

    # we also set a non-errored model just to ensure that it is not matched
    @foo_controller.instance_variable_set("@bbq", OpenStruct.new(:errors => []))
  end

  should "set an api key" do
    GuardrailNotifier.configure { |c| c.api_key = "Foo" }
    assert_equal "Foo", GuardrailNotifier.configuration.api_key
  end

  should "fallback to the ENV api key" do
    GuardrailNotifier.configure { |c| c.api_key = nil }
    ENV['GUARDRAIL_API_KEY'] = 'Cupcakes'
    assert_equal "Cupcakes", GuardrailNotifier.notifier_params[:api_key]
  end

  should "set secure" do
    GuardrailNotifier.configure { |c| c.secure = true }
    assert GuardrailNotifier.configuration.secure?
  end

  should "set a timeout_in_seconds" do
    assert_equal 5, GuardrailNotifier.configuration.timeout_in_seconds
    GuardrailNotifier.configure { |c| c.timeout_in_seconds = 6 }
    assert_equal 6, GuardrailNotifier.configuration.timeout_in_seconds
  end

  should "set monitored environments" do
    assert_equal ["production"], GuardrailNotifier.configuration.monitored_environments
    GuardrailNotifier.configure { |c| c.monitored_environments = ['stage', 'development'] }
    assert_equal ['stage', 'development'], GuardrailNotifier.configuration.monitored_environments
  end

  should "respect monitored environments" do
    assert @foo_controller.send(:should_log_failures_to_guardrail?)

    GuardrailNotifier.configuration.monitored_environments = ['stage', 'development']
    assert !@foo_controller.send(:should_log_failures_to_guardrail?)
  end

  should "identify no errors by default" do
    assert_equal [], FooController.new.send(:records_with_errors)
  end

  should "identify records with errors" do
    assert_same_elements [@model_one, @model_two, @model_three], @foo_controller.send(:records_with_errors)
  end

  should "create params via guardrail_params" do
    expected = [
      {"model"=>"OpenStruct", "field"=>"baz", "message"=>"is blank"},
      {"model"=>"OpenStruct", "field"=>"f1", "message"=>"is blank"},
      {"model"=>"OpenStruct", "field"=>"f2", "message"=>"is too large"},
      {"model"=>"OpenStruct", "field"=>"f2", "message"=>"is delicious"},
      {"model"=>"OpenStruct", "field"=>"bar", "message"=>"is blank"}
    ]

    params = @foo_controller.send(:guardrail_params)
    failures = JSON.parse(params[:failures])
    assert_same_elements expected, failures
  end

  # should "submit errors via log_validation_failures_to_guardrail" do
  #   Net::HTTP.expects(:post_form).with(URI.parse("http://api.guardrailapp.com:80"), @foo_controller.send(:guardrail_params))
  #   @foo_controller.send(:log_validation_failures_to_guardrail)
  # end

  should "log controller and action" do
    assert_equal @foo_controller.params['action'], @foo_controller.send(:guardrail_params)[:_action]
    assert_equal @foo_controller.params['controller'], @foo_controller.send(:guardrail_params)[:_controller]
  end

  should "log params" do
    @foo_controller.params.merge!('lolcats' => "no longer funny")
    assert_equal @foo_controller.params, JSON.parse(@foo_controller.send(:guardrail_params)[:data])['params']
  end

  should "filter tempfiles" do
    Tempfile.open('foo') do |tempfile|
      tempfile.write('test data')
      tempfile.rewind

      @foo_controller.params.merge!('value' => 'abc', 'photo' => tempfile, 'nested' => { 'nested_value' => 1, 'nested_photo' => tempfile })
      params = JSON.parse(@foo_controller.send(:guardrail_params)[:data])['params']
      assert_equal @foo_controller.params.merge('value' => 'abc', 'photo' => '[FILTERED]', 'nested' => { 'nested_value' => 1, 'nested_photo' => '[FILTERED]' }), params
    end
  end

  should "log current user's id if the method is exposed" do
    assert_equal nil, JSON.parse(@foo_controller.send(:guardrail_params)[:data])['current_user']
    assert_equal 53077, JSON.parse(fake_controller(BarController).send(:guardrail_params)[:data])['current_user']
  end

  should "handle exceptions" do
    logger = mock()
    logger.expects(:error)
    Rails.stubs(:logger => logger)

    @foo_controller.stubs(:guardrail_params).raises(StandardError)
    @foo_controller.send(:log_validation_failures_to_guardrail)

    # with a custom exception handler
    list = []
    GuardrailNotifier.configure { |c| c.on_exception = proc { |e| list << e } }

    logger.expects(:error)
    @foo_controller.send(:log_validation_failures_to_guardrail)

    assert_equal 1, list.size
    assert_kind_of StandardError, list.first
  end

  [:cookies, :user_agent].each do |kind|
    should "log #{kind}" do
      assert @foo_controller.request.send(kind).present?
      assert_equal @foo_controller.request.send(kind), JSON.parse(fake_controller(BarController).send(:guardrail_params)[:data])[kind.to_s]
    end
  end

  should "log session" do
    expected = {'something'=>'ok', 'some_class'=>'String', 'some_number'=>'42', 'some_array'=>['Date', '24']}
    assert_equal expected, JSON.parse(fake_controller(BarController).send(:guardrail_params)[:data])['session']
  end
end
