# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - Endpoints", type: :request do
  include_context "admin api authentication"

  let!(:organization) { create(:organization) }
  let!(:server) { create(:server, organization: organization) }

  describe "HTTP Endpoints" do
    describe "GET /api/v2/admin/organizations/:org/servers/:server/http_endpoints" do
      let!(:endpoint1) { create(:http_endpoint, server: server, name: "Webhook 1") }
      let!(:endpoint2) { create(:http_endpoint, server: server, name: "Webhook 2") }

      it "returns a list of HTTP endpoints" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/http_endpoints",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["http_endpoints"].length).to eq(2)
      end
    end

    describe "POST /api/v2/admin/organizations/:org/servers/:server/http_endpoints" do
      it "creates a new HTTP endpoint" do
        expect {
          post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/http_endpoints",
               params: {
                 name: "New Webhook",
                 url: "https://example.com/webhook",
                 encoding: "BodyAsJSON",
                 format: "Hash",
                 timeout: 30
               }.to_json,
               headers: json_headers
        }.to change(HTTPEndpoint, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["http_endpoint"]["name"]).to eq("New Webhook")
        expect(json_response["data"]["http_endpoint"]["url"]).to eq("https://example.com/webhook")
        expect(json_response["data"]["http_endpoint"]["timeout"]).to eq(30)
      end
    end

    describe "PATCH /api/v2/admin/organizations/:org/servers/:server/http_endpoints/:uuid" do
      let!(:endpoint) { create(:http_endpoint, server: server, name: "Original", url: "https://old.com") }

      it "updates the HTTP endpoint" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/http_endpoints/#{endpoint.uuid}",
              params: { url: "https://new.com/webhook" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(endpoint.reload.url).to eq("https://new.com/webhook")
      end
    end

    describe "DELETE /api/v2/admin/organizations/:org/servers/:server/http_endpoints/:uuid" do
      let!(:endpoint) { create(:http_endpoint, server: server) }

      it "deletes the HTTP endpoint" do
        expect {
          delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/http_endpoints/#{endpoint.uuid}",
                 headers: auth_headers
        }.to change(HTTPEndpoint, :count).by(-1)

        expect(response.status).to eq(200)
      end
    end
  end

  describe "SMTP Endpoints" do
    describe "GET /api/v2/admin/organizations/:org/servers/:server/smtp_endpoints" do
      let!(:endpoint1) { create(:smtp_endpoint, server: server, name: "SMTP 1") }
      let!(:endpoint2) { create(:smtp_endpoint, server: server, name: "SMTP 2") }

      it "returns a list of SMTP endpoints" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/smtp_endpoints",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["smtp_endpoints"].length).to eq(2)
      end
    end

    describe "POST /api/v2/admin/organizations/:org/servers/:server/smtp_endpoints" do
      it "creates a new SMTP endpoint" do
        expect {
          post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/smtp_endpoints",
               params: {
                 name: "New SMTP",
                 hostname: "smtp.example.com",
                 port: 587,
                 ssl_mode: "STARTTLS"
               }.to_json,
               headers: json_headers
        }.to change(SMTPEndpoint, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["smtp_endpoint"]["name"]).to eq("New SMTP")
        expect(json_response["data"]["smtp_endpoint"]["hostname"]).to eq("smtp.example.com")
        expect(json_response["data"]["smtp_endpoint"]["port"]).to eq(587)
      end
    end

    describe "PATCH /api/v2/admin/organizations/:org/servers/:server/smtp_endpoints/:uuid" do
      let!(:endpoint) { create(:smtp_endpoint, server: server, hostname: "old.smtp.com") }

      it "updates the SMTP endpoint" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/smtp_endpoints/#{endpoint.uuid}",
              params: { hostname: "new.smtp.com", port: 465 }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(endpoint.reload.hostname).to eq("new.smtp.com")
        expect(endpoint.port).to eq(465)
      end
    end

    describe "DELETE /api/v2/admin/organizations/:org/servers/:server/smtp_endpoints/:uuid" do
      let!(:endpoint) { create(:smtp_endpoint, server: server) }

      it "deletes the SMTP endpoint" do
        expect {
          delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/smtp_endpoints/#{endpoint.uuid}",
                 headers: auth_headers
        }.to change(SMTPEndpoint, :count).by(-1)

        expect(response.status).to eq(200)
      end
    end
  end

  describe "Address Endpoints" do
    describe "GET /api/v2/admin/organizations/:org/servers/:server/address_endpoints" do
      let!(:endpoint1) { create(:address_endpoint, server: server, address: "forward1@example.com") }
      let!(:endpoint2) { create(:address_endpoint, server: server, address: "forward2@example.com") }

      it "returns a list of address endpoints" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/address_endpoints",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["address_endpoints"].length).to eq(2)
      end
    end

    describe "POST /api/v2/admin/organizations/:org/servers/:server/address_endpoints" do
      it "creates a new address endpoint" do
        expect {
          post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/address_endpoints",
               params: { address: "forward@example.com" }.to_json,
               headers: json_headers
        }.to change(AddressEndpoint, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["address_endpoint"]["address"]).to eq("forward@example.com")
      end
    end

    describe "PATCH /api/v2/admin/organizations/:org/servers/:server/address_endpoints/:uuid" do
      let!(:endpoint) { create(:address_endpoint, server: server, address: "old@example.com") }

      it "updates the address endpoint" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/address_endpoints/#{endpoint.uuid}",
              params: { address: "new@example.com" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(endpoint.reload.address).to eq("new@example.com")
      end
    end

    describe "DELETE /api/v2/admin/organizations/:org/servers/:server/address_endpoints/:uuid" do
      let!(:endpoint) { create(:address_endpoint, server: server) }

      it "deletes the address endpoint" do
        expect {
          delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/address_endpoints/#{endpoint.uuid}",
                 headers: auth_headers
        }.to change(AddressEndpoint, :count).by(-1)

        expect(response.status).to eq(200)
      end
    end
  end
end
