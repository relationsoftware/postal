# frozen_string_literal: true

module AdminAPIHelper

  def admin_api_key
    @admin_api_key ||= "test-admin-api-key-12345"
  end

  def admin_api_headers
    { "X-Admin-API-Key" => admin_api_key }
  end

  def json_headers
    admin_api_headers.merge("Content-Type" => "application/json")
  end

  def setup_admin_api_key
    allow(Postal::Config.postal).to receive(:admin_api_key).and_return(admin_api_key)
  end

end
