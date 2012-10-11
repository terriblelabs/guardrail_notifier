require 'rubygems'
require 'test/unit'
require 'ostruct'
require 'shoulda'
gem 'actionpack', '~>3.2'
require 'action_controller'
require 'fakeweb'
require 'mocha'
require 'tempfile'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'guardrail_notifier'

class Test::Unit::TestCase
end

class FooController < ActionController::Base
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
