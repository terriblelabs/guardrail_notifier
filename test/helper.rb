require 'rubygems'
require 'redgreen'
require 'test/unit'
require 'ostruct'
require 'shoulda'
require 'action_controller'
require 'fakeweb'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'tripwire_notifier'

class Test::Unit::TestCase
end

class FooController < ActionController::Base
  filter_parameter_logging :password
end

class BarController < ActionController::Base
  def current_user
    "joe"
  end
end

class Rails
end
