require 'net/http'
require 'uri'
require 'timeout'

# TODO: namespace the methods apart from log_validation_failures_to_tripwire ?
module Tripwire
  module Notifier
    API_VERSION = "alpha 1"
    API_URL     = 'http://api.tripwireapp.com/'

    class << self
      attr_accessor :api_key, :monitored_environments, :timeout_in_seconds
    end

    def self.included(base)
      # set our defaults
      self.monitored_environments = ['production']
      self.timeout_in_seconds     = 5

      base.after_filter :log_validation_failures_to_tripwire, :only => [:create, :update]
    end

    def log_validation_failures_to_tripwire
      if should_log_failures_to_tripwire? && records_with_errors.present?
        begin
          timeout(Tripwire::Notifier.timeout_in_seconds) do
            Net::HTTP.post_form(
              URI.parse(API_URL),
              tripwire_params
            )
          end
        rescue Exception => ex
          warn "Could not submit tripwireapp notification: #{ex.class} - #{ex.message}" unless Rails.env.production?
        end
      end
    end

    private

    def should_log_failures_to_tripwire?
      Tripwire::Notifier.monitored_environments.include?(Rails.env.to_s)
    end

    def records_with_errors
      @records_with_errors ||= begin
        instance_variable_names.map do |var_name|
          var = instance_variable_get(var_name)
          if var.is_a?(Array)
            var.select{|v| record_has_errors?(v)}
          else
            var if record_has_errors?(var)
          end
        end.flatten.compact
      end
    end

    def record_has_errors?(record)
      record.respond_to?(:errors) && record.errors.present?
    end

    # TODO: remove assumptions about being called within a rails app (request, etc.) as part of framework agnosticism
    def tripwire_params
      # TODO: limit this in size - how big?
      data = {:params => filtered_params} # TODO: this is going to make controller and action redundant

      data.merge!(:current_user => current_user) if respond_to?(:current_user)
      data.merge!(
        :user_agent => request.user_agent,
        :cookies    => request.cookies,
        :session    => request.session
      )

      query = {
        :api_key     => Tripwire::Notifier.api_key,
        :api_version => Tripwire::Notifier::API_VERSION,
        :_controller => params['controller'],
        :_action     => params['action'],
        :path        => request.path,
        :data        => data.to_json
      }

      query[:failures] = records_with_errors.map do |record|
        record.errors.map do |field, messages|
          Array(messages).map do |message|
            {
              :model   => record.class.to_s,
              :field   => field,
              :message => message
            }
          end
        end
      end.flatten.to_json

      query
    end

    def filtered_params
      if respond_to?(:filter_parameters)
        filter_parameters(params)
      else
        params
      end
    end
  end
end

ActionController::Base.send(:include, Tripwire::Notifier)
