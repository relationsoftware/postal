# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - Servers", type: :request do
  include_context "admin api authentication"

  let!(:organization) { create(:organization) }

  describe "GET /api/v2/admin/organizations/:org/servers" do
    it_behaves_like "requires admin api authentication", :get, "/api/v2/admin/organizations/test-org/servers"

    context "with valid authentication" do
      let!(:server1) { create(:server, organization: organization, name: "Server Alpha") }
      let!(:server2) { create(:server, organization: organization, name: "Server Beta") }

      it "returns a list of servers" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers", headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["servers"].length).to eq(2)
        expect(json_response["data"]["servers"].map { |s| s["name"] }).to include("Server Alpha", "Server Beta")
      end

      it "includes server attributes" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers", headers: auth_headers
        server_data = json_response["data"]["servers"].find { |s| s["name"] == "Server Alpha" }
        expect(server_data).to include(
          "id" => server1.id,
          "uuid" => server1.uuid,
          "permalink" => server1.permalink,
          "suspended" => false
        )
      end
    end
  end

  describe "GET /api/v2/admin/organizations/:org/servers/:permalink" do
    let!(:server) { create(:server, organization: organization, name: "Test Server") }

    context "with valid authentication" do
      it "returns server details" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["server"]["name"]).to eq("Test Server")
      end

      it "includes domains, credentials, routes, and webhooks" do
        domain = create(:domain, owner: server)
        credential = create(:credential, server: server)
        route = create(:route, server: server)
        webhook = create(:webhook, server: server)

        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}",
            headers: auth_headers

        expect(json_response["data"]["server"]["domains"]).to be_an(Array)
        expect(json_response["data"]["server"]["credentials"]).to be_an(Array)
        expect(json_response["data"]["server"]["routes"]).to be_an(Array)
        expect(json_response["data"]["server"]["webhooks"]).to be_an(Array)
      end

      it "returns 404 for non-existent server" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/non-existent",
            headers: auth_headers
        expect(response.status).to eq(404)
        expect_error("NotFound", status: 404)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:org/servers" do
    context "with valid authentication" do
      it "creates a new server" do
        expect {
          post "/api/v2/admin/organizations/#{organization.permalink}/servers",
               params: { name: "New Server", mode: "Live" }.to_json,
               headers: json_headers
        }.to change(Server, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["server"]["name"]).to eq("New Server")
        expect(json_response["data"]["server"]["mode"]).to eq("Live")
      end

      it "creates server with custom settings" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers",
             params: {
               name: "Custom Server",
               mode: "Development",
               send_limit: 1000,
               message_retention_days: 30
             }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        server = Server.find_by(name: "Custom Server")
        expect(server.mode).to eq("Development")
        expect(server.send_limit).to eq(1000)
        expect(server.message_retention_days).to eq(30)
      end

      it "returns validation error for missing name" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers",
             params: { name: "" }.to_json,
             headers: json_headers

        expect(response.status).to eq(422)
        expect_error("ValidationError", status: 422)
      end
    end
  end

  describe "PATCH /api/v2/admin/organizations/:org/servers/:permalink" do
    let!(:server) { create(:server, organization: organization, name: "Original Server") }

    context "with valid authentication" do
      it "updates the server" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}",
              params: { name: "Updated Server" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect_success
        expect(server.reload.name).to eq("Updated Server")
      end

      it "updates server mode" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}",
              params: { mode: "Development" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(server.reload.mode).to eq("Development")
      end
    end
  end

  describe "DELETE /api/v2/admin/organizations/:org/servers/:permalink" do
    let!(:server) { create(:server, organization: organization, name: "To Delete") }

    context "with valid authentication" do
      it "soft deletes the server" do
        delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}",
               headers: auth_headers

        expect(response.status).to eq(200)
        expect(json_response["data"]["deleted"]).to eq(true)
        expect(server.reload.deleted_at).to be_present
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:org/servers/:permalink/suspend" do
    let!(:server) { create(:server, organization: organization) }

    context "with valid authentication" do
      it "suspends the server" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/suspend",
             params: { reason: "Policy violation" }.to_json,
             headers: json_headers

        expect(response.status).to eq(200)
        expect_success
        expect(server.reload.suspended?).to be true
        expect(server.suspension_reason).to eq("Policy violation")
      end

      it "uses default reason if not provided" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/suspend",
             headers: auth_headers

        expect(response.status).to eq(200)
        expect(server.reload.suspended?).to be true
        expect(server.suspension_reason).to eq("Suspended via Admin API")
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:org/servers/:permalink/unsuspend" do
    let!(:server) { create(:server, :suspended, organization: organization) }

    context "with valid authentication" do
      it "unsuspends the server" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/unsuspend",
             headers: auth_headers

        expect(response.status).to eq(200)
        expect_success
        expect(server.reload.suspended?).to be false
      end
    end
  end
end
