require 'helper'

class TestTripwire < Test::Unit::TestCase
  def fake_controller(klass)
    fake = klass.new
    fake.params = {'action' => "foo", 'controller' => "bar"}
    fake.request = OpenStruct.new(
      :user_agent => 'FooFox',
      :cookies => {'one' => 'two', 'three' => 'four'},
      :session => {'something' => 'ok', 'some_class' => String, 'some_number' => 42, :some_array => [Date, 24]}
    )
    fake.session = fake.request.session
    fake
  end

  def setup
    Rails.stubs(:env => 'production')

    @foo_controller = fake_controller(FooController)

    FakeWeb.register_uri(:post, 'http://api.tripwireapp.com', :body => "")

    TripwireNotifier.configure do |config|
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
    TripwireNotifier.configure { |c| c.api_key = "Foo" }
    assert_equal "Foo", TripwireNotifier.configuration.api_key
  end

  should "fallback to the ENV api key" do
    TripwireNotifier.configure { |c| c.api_key = nil }
    ENV['TRIPWIRE_API_KEY'] = 'Cupcakes'
    assert_equal "Cupcakes", TripwireNotifier.notifier_params[:api_key]
  end

  should "set secure" do
    TripwireNotifier.configure { |c| c.secure = true }
    assert TripwireNotifier.configuration.secure?
  end

  should "set a timeout_in_seconds" do
    assert_equal 5, TripwireNotifier.configuration.timeout_in_seconds
    TripwireNotifier.configure { |c| c.timeout_in_seconds = 6 }
    assert_equal 6, TripwireNotifier.configuration.timeout_in_seconds
  end

  should "set monitored environments" do
    assert_equal ["production"], TripwireNotifier.configuration.monitored_environments
    TripwireNotifier.configure { |c| c.monitored_environments = ['stage', 'development'] }
    assert_equal ['stage', 'development'], TripwireNotifier.configuration.monitored_environments
  end

  should "respect monitored environments" do
    assert @foo_controller.send(:should_log_failures_to_tripwire?)

    TripwireNotifier.configuration.monitored_environments = ['stage', 'development']
    assert !@foo_controller.send(:should_log_failures_to_tripwire?)
  end

  should "identify no errors by default" do
    assert_equal [], FooController.new.send(:records_with_errors)
  end

  should "identify records with errors" do
    assert_same_elements [@model_one, @model_two, @model_three], @foo_controller.send(:records_with_errors)
  end

  should "create params via tripwire_params" do
    expected = [
      {"model"=>"OpenStruct", "field"=>"baz", "message"=>"is blank"},
      {"model"=>"OpenStruct", "field"=>"f1", "message"=>"is blank"},
      {"model"=>"OpenStruct", "field"=>"f2", "message"=>"is too large"},
      {"model"=>"OpenStruct", "field"=>"f2", "message"=>"is delicious"},
      {"model"=>"OpenStruct", "field"=>"bar", "message"=>"is blank"}
    ]

    params = @foo_controller.send(:tripwire_params)
    failures = JSON.parse(params[:failures])
    assert_same_elements expected, failures
  end

  should "log flash messages" do
    ignored = "Something ignored"
    expected = "Something expected"

    @foo_controller.session['flash'] = {'error' => expected, 'notice' => ignored}

    params = @foo_controller.send(:tripwire_params)
    failures = JSON.parse(params[:failures])

    assert failures.include?({'model' => 'flash', 'field' => 'error', 'message' => expected})
    assert !failures.include?({'model' => 'flash', 'field' => 'notice', 'message' => ignored})
  end

  should "log flash messages matching specified key regex" do
    # add a regex to match any key containing 'error'
    TripwireNotifier.configure { |c| c.monitored_flash_keys << /error/ }

    ignored = "Something ignored"
    expected = "Something expected"
    @foo_controller.session['flash'] = {'error' => expected, 'another_error' => expected, 'notice' => ignored}

    params = @foo_controller.send(:tripwire_params)
    failures = JSON.parse(params[:failures])

    assert failures.include?({'model' => 'flash', 'field' => 'error', 'message' => expected})
    assert failures.include?({'model' => 'flash', 'field' => 'another_error', 'message' => expected})
    assert !failures.include?({'model' => 'flash', 'field' => 'notice', 'message' => ignored})
  end

  # should "submit errors via log_validation_failures_to_tripwire" do
  #   Net::HTTP.expects(:post_form).with(URI.parse("http://api.tripwireapp.com:80"), @foo_controller.send(:tripwire_params))
  #   @foo_controller.send(:log_validation_failures_to_tripwire)
  # end

  should "log controller and action" do
    assert_equal @foo_controller.params['action'], @foo_controller.send(:tripwire_params)[:_action]
    assert_equal @foo_controller.params['controller'], @foo_controller.send(:tripwire_params)[:_controller]
  end

  should "log params" do
    @foo_controller.params.merge!('lolcats' => "no longer funny")
    assert_equal @foo_controller.params, JSON.parse(@foo_controller.send(:tripwire_params)[:data])['params']
  end

  should "filter params" do
    @foo_controller.params.merge!('password' => "do not show", 'password_confirmation' => 'rollerskates')
    assert_equal @foo_controller.params.merge('password' => "[FILTERED]", 'password_confirmation' => '[FILTERED]'), JSON.parse(@foo_controller.send(:tripwire_params)[:data])['params']
  end

  should "filter tempfiles" do
    Tempfile.open('foo') do |tempfile|
      tempfile.write('test data')
      tempfile.rewind

      @foo_controller.params.merge!('value' => 'abc', 'photo' => tempfile, 'nested' => { 'nested_value' => 1, 'nested_photo' => tempfile })
      params = JSON.parse(@foo_controller.send(:tripwire_params)[:data])['params']
      assert_equal @foo_controller.params.merge('value' => 'abc', 'photo' => '[FILTERED]', 'nested' => { 'nested_value' => 1, 'nested_photo' => '[FILTERED]' }), params
    end
  end

  should "log current user's id if the method is exposed" do
    assert_equal nil, JSON.parse(@foo_controller.send(:tripwire_params)[:data])['current_user']
    assert_equal 53077, JSON.parse(fake_controller(BarController).send(:tripwire_params)[:data])['current_user']
  end

  should "handle exceptions" do
    logger = mock()
    logger.expects(:error)
    Rails.stubs(:logger => logger)

    @foo_controller.stubs(:tripwire_params).raises(StandardError)
    @foo_controller.send(:log_validation_failures_to_tripwire)

    # with a custom exception handler
    list = []
    TripwireNotifier.configure { |c| c.on_exception = proc { |e| list << e } }

    logger.expects(:error)
    @foo_controller.send(:log_validation_failures_to_tripwire)

    assert_equal 1, list.size
    assert_kind_of StandardError, list.first
  end

  [:cookies, :user_agent].each do |kind|
    should "log #{kind}" do
      assert @foo_controller.request.send(kind).present?
      assert_equal @foo_controller.request.send(kind), JSON.parse(fake_controller(BarController).send(:tripwire_params)[:data])[kind.to_s]
    end
  end

  should "log session" do
    expected = {'something'=>'ok', 'some_class'=>'String', 'some_number'=>'42', 'some_array'=>['Date', '24']}
    assert_equal expected, JSON.parse(fake_controller(BarController).send(:tripwire_params)[:data])['session']
  end
end
