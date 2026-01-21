# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - Credentials", type: :request do
  include_context "admin api authentication"

  let!(:organization) { create(:organization) }
  let!(:server) { create(:server, organization: organization) }

  describe "GET /api/v2/admin/organizations/:org/servers/:server/credentials" do
    let!(:cred1) { create(:credential, server: server, name: "API Key 1", type: "API") }
    let!(:cred2) { create(:credential, server: server, name: "SMTP Key", type: "SMTP") }

    context "with valid authentication" do
      it "returns a list of credentials" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/credentials",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["credentials"].length).to eq(2)
      end

      it "includes credential attributes but not keys in list" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/credentials",
            headers: auth_headers
        cred_data = json_response["data"]["credentials"].find { |c| c["name"] == "API Key 1" }
        expect(cred_data).to include(
          "id" => cred1.id,
          "uuid" => cred1.uuid,
          "type" => "API",
          "hold" => false
        )
        expect(cred_data).not_to have_key("key")
      end
    end
  end

  describe "GET /api/v2/admin/organizations/:org/servers/:server/credentials/:uuid" do
    let!(:credential) { create(:credential, server: server, name: "Test Credential", type: "SMTP") }

    context "with valid authentication" do
      it "returns credential details including key" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/credentials/#{credential.uuid}",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["credential"]["name"]).to eq("Test Credential")
        expect(json_response["data"]["credential"]["key"]).to eq(credential.key)
        expect(json_response["data"]["credential"]["smtp_username"]).to eq(credential.key)
        expect(json_response["data"]["credential"]["smtp_password"]).to eq(credential.key)
      end

      it "returns 404 for non-existent credential" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/credentials/non-existent-uuid",
            headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:org/servers/:server/credentials" do
    context "with valid authentication" do
      it "creates a new SMTP credential" do
        expect {
          post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/credentials",
               params: { name: "New SMTP", type: "SMTP" }.to_json,
               headers: json_headers
        }.to change(Credential, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["credential"]["name"]).to eq("New SMTP")
        expect(json_response["data"]["credential"]["type"]).to eq("SMTP")
        expect(json_response["data"]["credential"]["key"]).to be_present
      end

      it "creates a new API credential" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/credentials",
             params: { name: "New API", type: "API" }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["credential"]["type"]).to eq("API")
      end

      it "creates a new SMTP-IP credential with specified key" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/credentials",
             params: { name: "IP Auth", type: "SMTP-IP", key: "192.168.1.100" }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["credential"]["type"]).to eq("SMTP-IP")
        expect(json_response["data"]["credential"]["key"]).to eq("192.168.1.100")
      end

      it "creates credential with hold enabled" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/credentials",
             params: { name: "Held Credential", type: "SMTP", hold: true }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["credential"]["hold"]).to eq(true)
      end

      it "returns validation error for missing name" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/credentials",
             params: { name: "", type: "SMTP" }.to_json,
             headers: json_headers

        expect(response.status).to eq(422)
        expect_error("ValidationError", status: 422)
      end
    end
  end

  describe "PATCH /api/v2/admin/organizations/:org/servers/:server/credentials/:uuid" do
    let!(:credential) { create(:credential, server: server, name: "Original Name", hold: false) }

    context "with valid authentication" do
      it "updates the credential name" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/credentials/#{credential.uuid}",
              params: { name: "Updated Name" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect_success
        expect(credential.reload.name).to eq("Updated Name")
      end

      it "updates hold status" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/credentials/#{credential.uuid}",
              params: { hold: true }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(credential.reload.hold).to eq(true)
      end
    end
  end

  describe "DELETE /api/v2/admin/organizations/:org/servers/:server/credentials/:uuid" do
    let!(:credential) { create(:credential, server: server, name: "To Delete") }

    context "with valid authentication" do
      it "deletes the credential" do
        expect {
          delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/credentials/#{credential.uuid}",
                 headers: auth_headers
        }.to change(Credential, :count).by(-1)

        expect(response.status).to eq(200)
        expect(json_response["data"]["deleted"]).to eq(true)
      end
    end
  end
end
