require 'rubygems'
require 'rake'
require File.dirname(__FILE__) + "/lib/tripwire_notifier/version.rb"

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.version = TripwireNotifier::VERSION
    gem.name = "tripwire_notifier"
    gem.summary = %Q{Tripwire (http://tripwireapp.com) captures validation errors from your Ruby on Rails application.}
    gem.description = %Q{Tripwire captures validation errors from your Ruby on Rails application to help you identify and fix user experience issues. The TripwireNotifier gem makes it easy to hook up your app to the Tripwire web service.}
    gem.email = "support@tripwireapp.com"
    gem.homepage = "http://github.com/jeremyw/tripwire_notifier"
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

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = TripwireNotifier::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "tripwire_notifier #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
