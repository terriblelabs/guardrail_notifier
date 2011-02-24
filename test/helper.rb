require 'rubygems'
require 'redgreen'
require 'test/unit'
require 'ostruct'
require 'shoulda'
require 'action_controller'
require 'fakeweb'
require 'mocha'
require 'tempfile'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'tripwire_notifier'

class Test::Unit::TestCase
end

class FooController < ActionController::Base
  filter_parameter_logging :password
end

class User
  attr_accessor :id
  def initialize
    @id = 53077
  end
end

class BarController < ActionController::Base
  def current_user
    User.new
  end
end

class Rails
end
