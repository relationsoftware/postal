# frozen_string_literal: true

ENV["POSTAL_CONFIG_FILE_PATH"] ||= "config/postal/postal.test.yml"

require "dotenv"
Dotenv.load(".env.test")

require File.expand_path("../config/environment", __dir__)
require "rspec/rails"
require "spec_helper"
require "factory_bot"
require "timecop"
require "webmock/rspec"
require "shoulda-matchers"
require "rspec/openapi"
ActiveRecord::Base.logger = Logger.new("/dev/null")

# Speed up the suite: has_secure_password uses BCrypt, which at the default
# cost (~12) spends ~250ms hashing each password. The specs create many users
# and credentials, so use BCrypt's minimum cost in tests.
ActiveModel::SecurePassword.min_cost = true

# Postal signs outgoing messages (DKIM) with the RSA key at
# Postal::Config.postal.signing_key_path. That file is not checked in, so
# generate an ephemeral key for the test run if it is missing - otherwise
# every spec that adds outgoing headers fails with Errno::ENOENT.
begin
  signing_key_path = Postal::Config.postal.signing_key_path
  unless File.exist?(signing_key_path)
    require "openssl"
    require "fileutils"
    FileUtils.mkdir_p(File.dirname(signing_key_path))
    File.write(signing_key_path, OpenSSL::PKey::RSA.new(2048).to_pem)
  end
end

Dir[File.expand_path("helpers/**/*.rb", __dir__)].each { |f| require f }

ActionMailer::Base.delivery_method = :test

unless ENV["SKIP_PENDING_MIGRATIONS"] == "1"
  ActiveRecord::Migration.maintain_test_schema!
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.include FactoryBot::Syntax::Methods
  config.include GeneralHelpers
  config.include AdminAPIHelper

  config.before(:suite) do
    if ENV["OPENAPI_FILE"].to_s.include?("postal-api.yml")
      RSpec::OpenAPI.path = "public/openapi/postal-api.yml"
      RSpec::OpenAPI.security_schemes = {
        "ServerAPIKey" => {
          type: "apiKey",
          name: "X-Server-API-Key",
          in: "header",
          description: "Server API Key for authenticating with the Postal Mail API"
        }
      }
    else
      RSpec::OpenAPI.path = "public/openapi/postal-admin-api.yaml"
      RSpec::OpenAPI.security_schemes = {
        "AdminAPIKey" => {
          type: "apiKey",
          name: "X-Admin-API-Key",
          in: "header",
          description: "Admin API Key for authenticating with the Postal Admin API"
        }
      }
    end
  end
end
