# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - Users", type: :request do
  include_context "admin api authentication"

  describe "GET /api/v2/admin/users" do
    let!(:user1) { create(:user, email_address: "alpha@example.com") }
    let!(:user2) { create(:user, email_address: "beta@example.com") }

    context "with valid authentication" do
      it "returns a list of users" do
        get "/api/v2/admin/users", headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["users"].length).to eq(2)
      end

      it "includes user attributes" do
        get "/api/v2/admin/users", headers: auth_headers
        user_data = json_response["data"]["users"].find { |u| u["email_address"] == "alpha@example.com" }
        expect(user_data).to include(
          "id" => user1.id,
          "uuid" => user1.uuid,
          "first_name" => user1.first_name,
          "last_name" => user1.last_name,
          "admin" => user1.admin?
        )
      end
    end
  end

  describe "GET /api/v2/admin/users/:id" do
    let!(:user) { create(:user, email_address: "test@example.com", first_name: "Test", last_name: "User") }

    context "with valid authentication" do
      it "returns user details by uuid" do
        get "/api/v2/admin/users/#{user.uuid}", headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["user"]["email_address"]).to eq("test@example.com")
        expect(json_response["data"]["user"]["name"]).to eq("Test User")
      end

      it "returns user details by email" do
        get "/api/v2/admin/users/test@example.com", headers: auth_headers
        expect(response.status).to eq(200)
        expect(json_response["data"]["user"]["uuid"]).to eq(user.uuid)
      end

      it "includes organizations list" do
        org = create(:organization)
        org.organization_users.create!(user: user, admin: true, all_servers: true)

        get "/api/v2/admin/users/#{user.uuid}", headers: auth_headers
        expect(json_response["data"]["user"]["organizations"]).to be_an(Array)
        expect(json_response["data"]["user"]["organizations"].first["name"]).to eq(org.name)
      end

      it "returns 404 for non-existent user" do
        get "/api/v2/admin/users/non-existent", headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /api/v2/admin/users" do
    context "with valid authentication" do
      it "creates a new user" do
        expect {
          post "/api/v2/admin/users",
               params: {
                 email_address: "new@example.com",
                 first_name: "New",
                 last_name: "User",
                 password: "securepassword123"
               }.to_json,
               headers: json_headers
        }.to change(User, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["user"]["email_address"]).to eq("new@example.com")
      end

      it "creates admin user" do
        post "/api/v2/admin/users",
             params: {
               email_address: "admin@example.com",
               first_name: "Admin",
               last_name: "User",
               password: "securepassword123",
               admin: true
             }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["user"]["admin"]).to eq(true)
      end

      it "creates user with time_zone" do
        post "/api/v2/admin/users",
             params: {
               email_address: "tz@example.com",
               first_name: "TZ",
               last_name: "User",
               password: "securepassword123",
               time_zone: "America/New_York"
             }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["user"]["time_zone"]).to eq("America/New_York")
      end

      it "returns validation error for missing email" do
        post "/api/v2/admin/users",
             params: {
               first_name: "No",
               last_name: "Email",
               password: "securepassword123"
             }.to_json,
             headers: json_headers

        expect(response.status).to eq(422)
        expect_error("ValidationError", status: 422)
      end

      it "returns validation error for duplicate email" do
        create(:user, email_address: "existing@example.com")

        post "/api/v2/admin/users",
             params: {
               email_address: "existing@example.com",
               first_name: "Duplicate",
               last_name: "User",
               password: "securepassword123"
             }.to_json,
             headers: json_headers

        expect(response.status).to eq(422)
        expect_error("ValidationError", status: 422)
      end
    end
  end

  describe "PATCH /api/v2/admin/users/:id" do
    let!(:user) { create(:user, first_name: "Original", last_name: "Name") }

    context "with valid authentication" do
      it "updates the user" do
        patch "/api/v2/admin/users/#{user.uuid}",
              params: { first_name: "Updated", last_name: "User" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect_success
        expect(user.reload.first_name).to eq("Updated")
        expect(user.last_name).to eq("User")
      end

      it "updates password" do
        old_digest = user.password_digest

        patch "/api/v2/admin/users/#{user.uuid}",
              params: { password: "newpassword123" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(user.reload.password_digest).not_to eq(old_digest)
      end

      it "promotes user to admin" do
        patch "/api/v2/admin/users/#{user.uuid}",
              params: { admin: true }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(user.reload.admin?).to eq(true)
      end
    end
  end

  describe "DELETE /api/v2/admin/users/:id" do
    let!(:user) { create(:user) }

    context "with valid authentication" do
      it "deletes the user" do
        expect {
          delete "/api/v2/admin/users/#{user.uuid}", headers: auth_headers
        }.to change(User, :count).by(-1)

        expect(response.status).to eq(200)
        expect(json_response["data"]["deleted"]).to eq(true)
      end
    end
  end
end
