# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# Configure inflections BEFORE Rails loads (before Zeitwerk is initialized)
require "active_support"
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "HTTP"
  inflect.acronym "SMTP"
  inflect.acronym "API"
  inflect.acronym "DNS"
  inflect.acronym "IP"
end

require_relative "../lib/postal/config"

# Only set RAILS_ENV from config if not already set and config is available
unless ENV["RAILS_ENV"]
  begin
    ENV["RAILS_ENV"] = Postal::Config.rails.environment || "development"
  rescue StandardError
    # Config might not be available during asset precompilation
    ENV["RAILS_ENV"] ||= "development"
  end
end
