# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - Domains", type: :request do
  include_context "admin api authentication"

  let!(:organization) { create(:organization) }
  let!(:server) { create(:server, organization: organization) }

  describe "GET /api/v2/admin/organizations/:org/servers/:server/domains" do
    let!(:domain1) { create(:domain, owner: server, name: "alpha.example.com") }
    let!(:domain2) { create(:domain, owner: server, name: "beta.example.com") }

    context "with valid authentication" do
      it "returns a list of domains" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["domains"].length).to eq(2)
        expect(json_response["data"]["domains"].map { |d| d["name"] }).to include("alpha.example.com", "beta.example.com")
      end

      it "includes domain attributes" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains",
            headers: auth_headers
        domain_data = json_response["data"]["domains"].find { |d| d["name"] == "alpha.example.com" }
        expect(domain_data).to include(
          "id" => domain1.id,
          "uuid" => domain1.uuid,
          "verified" => false
        )
      end
    end
  end

  describe "GET /api/v2/admin/organizations/:org/servers/:server/domains/:id" do
    let!(:domain) { create(:domain, owner: server, name: "test.example.com") }

    context "with valid authentication" do
      it "returns domain details with DNS info" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/#{domain.uuid}",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["domain"]["name"]).to eq("test.example.com")
        expect(json_response["data"]["domain"]["dns"]).to be_a(Hash)
        expect(json_response["data"]["domain"]["dns"]).to include("spf", "dkim", "mx", "return_path")
      end

      it "can find domain by name" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/test.example.com",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect(json_response["data"]["domain"]["name"]).to eq("test.example.com")
      end

      it "returns 404 for non-existent domain" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/non-existent",
            headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:org/servers/:server/domains" do
    context "with valid authentication" do
      it "creates a new domain" do
        expect {
          post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains",
               params: { name: "new.example.com" }.to_json,
               headers: json_headers
        }.to change(Domain, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["domain"]["name"]).to eq("new.example.com")
      end

      it "returns DNS setup information" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains",
             params: { name: "setup.example.com" }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["domain"]["dns"]).to be_present
        expect(json_response["data"]["domain"]["dkim_identifier"]).to be_present
      end

      it "returns validation error for invalid domain" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains",
             params: { name: "" }.to_json,
             headers: json_headers

        expect(response.status).to eq(422)
        expect_error("ValidationError", status: 422)
      end

      it "returns validation error for duplicate domain" do
        create(:domain, owner: server, name: "existing.example.com")

        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains",
             params: { name: "existing.example.com" }.to_json,
             headers: json_headers

        expect(response.status).to eq(422)
        expect_error("ValidationError", status: 422)
      end
    end
  end

  describe "DELETE /api/v2/admin/organizations/:org/servers/:server/domains/:id" do
    let!(:domain) { create(:domain, owner: server, name: "to-delete.example.com") }

    context "with valid authentication" do
      it "deletes the domain" do
        expect {
          delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/#{domain.uuid}",
                 headers: auth_headers
        }.to change(Domain, :count).by(-1)

        expect(response.status).to eq(200)
        expect(json_response["data"]["deleted"]).to eq(true)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:org/servers/:server/domains/:id/verify" do
    let!(:domain) { create(:domain, owner: server, name: "verify.example.com") }

    context "with valid authentication" do
      it "triggers DNS verification" do
        expect_any_instance_of(Domain).to receive(:check_dns).with(:all)

        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/#{domain.uuid}/verify",
             headers: auth_headers

        expect(response.status).to eq(200)
        expect_success
      end
    end
  end
end
