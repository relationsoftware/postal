# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - Organization Users", type: :request do
  include_context "admin api authentication"

  let!(:organization) { create(:organization) }
  let!(:user1) { create(:user, email_address: "user1@example.com") }
  let!(:user2) { create(:user, email_address: "user2@example.com") }

  before do
    organization.organization_users.create!(user: user1, admin: true, all_servers: true)
  end

  describe "GET /api/v2/admin/organizations/:organization_id/users" do
    context "with valid authentication" do
      it "returns a list of organization users" do
        get "/api/v2/admin/organizations/#{organization.permalink}/users", headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["users"]).to be_an(Array)
        expect(json_response["data"]["users"].length).to eq(1)
      end

      it "includes user attributes" do
        get "/api/v2/admin/organizations/#{organization.permalink}/users", headers: auth_headers
        user_data = json_response["data"]["users"].first
        expect(user_data).to include(
          "email_address" => "user1@example.com",
          "admin" => true,
          "all_servers" => true
        )
      end

      it "includes pagination info" do
        get "/api/v2/admin/organizations/#{organization.permalink}/users", headers: auth_headers
        expect(json_response["data"]["pagination"]).to include("page", "per_page")
      end

      it "returns 404 for non-existent organization" do
        get "/api/v2/admin/organizations/non-existent/users", headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end

  describe "GET /api/v2/admin/organizations/:organization_id/users/:id" do
    context "with valid authentication" do
      it "returns user details by UUID" do
        get "/api/v2/admin/organizations/#{organization.permalink}/users/#{user1.uuid}",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["user"]["email_address"]).to eq("user1@example.com")
        expect(json_response["data"]["user"]["admin"]).to eq(true)
      end

      it "returns user details by email address" do
        get "/api/v2/admin/organizations/#{organization.permalink}/users/#{user1.email_address}",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["user"]["uuid"]).to eq(user1.uuid)
      end

      it "returns 404 for user not in organization" do
        get "/api/v2/admin/organizations/#{organization.permalink}/users/#{user2.uuid}",
            headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:organization_id/users/add" do
    context "with valid authentication" do
      it "adds a user to the organization" do
        expect do
          post "/api/v2/admin/organizations/#{organization.permalink}/users/add",
               params: { email: user2.email_address, admin: false, all_servers: true }.to_json,
               headers: json_headers
        end.to change { organization.organization_users.count }.by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["user"]["email_address"]).to eq("user2@example.com")
        expect(json_response["data"]["user"]["all_servers"]).to eq(true)
      end

      it "adds a user as admin" do
        post "/api/v2/admin/organizations/#{organization.permalink}/users/add",
             params: { email: user2.email_address, admin: true }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["user"]["admin"]).to eq(true)
      end

      it "returns error for non-existent user" do
        post "/api/v2/admin/organizations/#{organization.permalink}/users/add",
             params: { email: "nonexistent@example.com" }.to_json,
             headers: json_headers

        expect(response.status).to eq(404)
      end
    end
  end

  describe "PATCH /api/v2/admin/organizations/:organization_id/users/:id" do
    context "with valid authentication" do
      it "updates user admin status" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/users/#{user1.uuid}",
              params: { admin: false }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["user"]["admin"]).to eq(false)
      end

      it "updates all_servers flag" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/users/#{user1.uuid}",
              params: { all_servers: false }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(json_response["data"]["user"]["all_servers"]).to eq(false)
      end

      it "returns 404 for user not in organization" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/users/#{user2.uuid}",
              params: { admin: false }.to_json,
              headers: json_headers

        expect(response.status).to eq(404)
      end
    end
  end

  describe "DELETE /api/v2/admin/organizations/:organization_id/users/:id" do
    context "with valid authentication" do
      it "removes user from organization" do
        expect do
          delete "/api/v2/admin/organizations/#{organization.permalink}/users/#{user1.uuid}",
                 headers: auth_headers
        end.to change { organization.organization_users.count }.by(-1)

        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["deleted"]).to eq(true)
      end

      it "does not delete the user account" do
        expect do
          delete "/api/v2/admin/organizations/#{organization.permalink}/users/#{user1.uuid}",
                 headers: auth_headers
        end.not_to change(User, :count)
      end

      it "returns 404 for user not in organization" do
        delete "/api/v2/admin/organizations/#{organization.permalink}/users/#{user2.uuid}",
               headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end
end
