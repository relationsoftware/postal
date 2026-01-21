# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - Organizations", type: :request do
  include_context "admin api authentication"

  describe "GET /api/v2/admin/organizations" do
    it_behaves_like "requires admin api authentication", :get, "/api/v2/admin/organizations"

    context "with valid authentication" do
      let!(:org1) { create(:organization, name: "Alpha Org") }
      let!(:org2) { create(:organization, name: "Beta Org") }

      it "returns a list of organizations" do
        get "/api/v2/admin/organizations", headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["organizations"].length).to eq(2)
        expect(json_response["data"]["organizations"].map { |o| o["name"] }).to include("Alpha Org", "Beta Org")
      end

      it "includes pagination info" do
        get "/api/v2/admin/organizations", headers: auth_headers
        expect(json_response["data"]["pagination"]).to include(
          "page" => 1,
          "per_page" => 25,
          "total" => 2
        )
      end

      it "supports pagination parameters" do
        get "/api/v2/admin/organizations", params: { page: 1, per_page: 1 }, headers: auth_headers
        expect(json_response["data"]["organizations"].length).to eq(1)
        expect(json_response["data"]["pagination"]["per_page"]).to eq(1)
      end
    end
  end

  describe "GET /api/v2/admin/organizations/:permalink" do
    let!(:organization) { create(:organization, name: "Test Org") }

    it_behaves_like "requires admin api authentication", :get, "/api/v2/admin/organizations/test-org"

    context "with valid authentication" do
      it "returns the organization details" do
        get "/api/v2/admin/organizations/#{organization.permalink}", headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["organization"]["name"]).to eq("Test Org")
        expect(json_response["data"]["organization"]["permalink"]).to eq(organization.permalink)
        expect(json_response["data"]["organization"]["uuid"]).to eq(organization.uuid)
      end

      it "includes servers list" do
        server = create(:server, organization: organization, name: "Mail Server")
        get "/api/v2/admin/organizations/#{organization.permalink}", headers: auth_headers
        expect(json_response["data"]["organization"]["servers"]).to be_an(Array)
        expect(json_response["data"]["organization"]["servers"].first["name"]).to eq("Mail Server")
      end

      it "returns 404 for non-existent organization" do
        get "/api/v2/admin/organizations/non-existent", headers: auth_headers
        expect(response.status).to eq(404)
        expect_error("NotFound", status: 404)
      end
    end
  end

  describe "POST /api/v2/admin/organizations" do
    it_behaves_like "requires admin api authentication", :post, "/api/v2/admin/organizations"

    context "with valid authentication" do
      it "creates a new organization" do
        expect {
          post "/api/v2/admin/organizations",
               params: { name: "New Organization" }.to_json,
               headers: json_headers
        }.to change(Organization, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["organization"]["name"]).to eq("New Organization")
      end

      it "creates organization with custom permalink" do
        post "/api/v2/admin/organizations",
             params: { name: "Custom Org", permalink: "custom-permalink" }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["organization"]["permalink"]).to eq("custom-permalink")
      end

      it "creates organization with owner" do
        user = create(:user)
        post "/api/v2/admin/organizations",
             params: { name: "Owned Org", owner_email: user.email_address }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        org = Organization.find_by(name: "Owned Org")
        expect(org.owner).to eq(user)
        expect(org.organization_users.find_by(user: user)).to be_present
      end

      it "returns validation error for missing name" do
        post "/api/v2/admin/organizations",
             params: { name: "" }.to_json,
             headers: json_headers

        expect(response.status).to eq(422)
        expect_error("ValidationError", status: 422)
      end
    end
  end

  describe "PATCH /api/v2/admin/organizations/:permalink" do
    let!(:organization) { create(:organization, name: "Original Name") }

    it_behaves_like "requires admin api authentication", :patch, "/api/v2/admin/organizations/original-name"

    context "with valid authentication" do
      it "updates the organization" do
        patch "/api/v2/admin/organizations/#{organization.permalink}",
              params: { name: "Updated Name" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect_success
        expect(organization.reload.name).to eq("Updated Name")
      end

      it "updates time_zone" do
        patch "/api/v2/admin/organizations/#{organization.permalink}",
              params: { time_zone: "America/New_York" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(organization.reload.time_zone).to eq("America/New_York")
      end
    end
  end

  describe "DELETE /api/v2/admin/organizations/:permalink" do
    let!(:organization) { create(:organization, name: "To Delete") }

    it_behaves_like "requires admin api authentication", :delete, "/api/v2/admin/organizations/to-delete"

    context "with valid authentication" do
      it "soft deletes the organization" do
        delete "/api/v2/admin/organizations/#{organization.permalink}", headers: auth_headers

        expect(response.status).to eq(200)
        expect(json_response["data"]["deleted"]).to eq(true)
        expect(organization.reload.deleted_at).to be_present
      end
    end
  end
end
