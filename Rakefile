require 'rubygems'
require 'rake'
require File.dirname(__FILE__) + "/lib/guardrail_notifier/version.rb"

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.version = GuardrailNotifier::VERSION
    gem.name = "guardrail_notifier"
    gem.summary = %Q{Guardrail (http://guardrailapp.com) captures validation errors from your Ruby on Rails application.}
    gem.description = %Q{Guardrail captures validation errors from your Ruby on Rails application to help you identify and fix user experience issues. The GuardrailNotifier gem makes it easy to hook up your app to the Guardrail web service.}
    gem.email = "support@guardrailapp.com"
    gem.homepage = "http://github.com/terriblelabs/guardrail_notifier"
    gem.authors = ["Jeffrey Chupp", "Jeremy Weiskotten"]
    gem.add_development_dependency "shoulda", ">= 0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = GuardrailNotifier::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "guardrail_notifier #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
