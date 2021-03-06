# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "guardrail_notifier"
  s.version = "0.2.12"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jeffrey Chupp", "Jeremy Weiskotten"]
  s.date = "2012-10-13"
  s.description = "Guardrail captures validation errors from your Ruby on Rails application to help you identify and fix user experience issues. The GuardrailNotifier gem makes it easy to hook up your app to the Guardrail web service."
  s.email = "support@guardrailapp.com"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "guardrail_notifier.gemspec",
    "lib/guardrail_notifier.rb",
    "lib/guardrail_notifier/configuration.rb",
    "lib/guardrail_notifier/rails/action_controller_monitor.rb",
    "lib/guardrail_notifier/sender.rb",
    "lib/guardrail_notifier/version.rb",
    "test/guardrail_test.rb",
    "test/helper.rb",
    "test/sender_test.rb"
  ]
  s.homepage = "http://github.com/terriblelabs/guardrail_notifier"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Guardrail (http://guardrailapp.com) captures validation errors from your Ruby on Rails application."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<actionpack>, ["= 3.2.8"])
      s.add_development_dependency(%q<json>, [">= 0"])
      s.add_development_dependency(%q<fakeweb>, [">= 0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
    else
      s.add_dependency(%q<actionpack>, ["= 3.2.8"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<fakeweb>, [">= 0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<actionpack>, ["= 3.2.8"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<fakeweb>, [">= 0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
  end
end

