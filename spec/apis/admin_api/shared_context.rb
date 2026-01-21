# frozen_string_literal: true

RSpec.shared_context "admin api authentication" do
  let(:admin_api_key) { "test-admin-api-key-12345" }
  let(:auth_headers) { { "X-Admin-API-Key" => admin_api_key } }
  let(:json_headers) { auth_headers.merge("Content-Type" => "application/json") }

  before do
    allow(Postal::Config.postal).to receive(:admin_api_key).and_return(admin_api_key)
  end

  def json_response
    JSON.parse(response.body)
  end

  def expect_success
    expect(json_response["status"]).to eq("success")
  end

  def expect_error(code, status: nil)
    expect(json_response["status"]).to eq("error")
    expect(json_response["error"]["code"]).to eq(code)
    expect(response.status).to eq(status) if status
  end
end

RSpec.shared_examples "requires admin api authentication" do |method, path|
  context "without authentication" do
    it "returns unauthorized error" do
      send(method, path)
      expect(response.status).to eq(401)
      parsed = JSON.parse(response.body)
      expect(parsed["status"]).to eq("error")
      expect(parsed["error"]["code"]).to eq("Unauthorized")
    end
  end

  context "with invalid api key" do
    it "returns unauthorized error" do
      send(method, path, headers: { "X-Admin-API-Key" => "invalid-key" })
      expect(response.status).to eq(401)
      parsed = JSON.parse(response.body)
      expect(parsed["status"]).to eq("error")
      expect(parsed["error"]["code"]).to eq("Unauthorized")
    end
  end
end
