# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminAPI::UsersController, type: :request do
  include AdminAPIHelper
  include_context "admin api authentication"

  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }

  describe "GET /api/v2/admin/users" do
    let(:req_method) { :get }
    let(:req_path) { "/api/v2/admin/users" }
    it_behaves_like "requires admin api authentication"

    context "with valid authentication" do
      it "returns a paginated list of users" do
        get "/api/v2/admin/users",
            headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["data"]["users"]).to be_an(Array)
        expect(json["data"]["users"].map { |u| u["uuid"] }).to include(user.uuid)
      end
    end
  end

  describe "GET /api/v2/admin/users/:id" do
    let(:req_method) { :get }
    let(:req_path) { "/api/v2/admin/users/#{user.uuid}" }
    it_behaves_like "requires admin api authentication"

    context "with valid authentication" do
      it "returns user details by UUID" do
        get "/api/v2/admin/users/#{user.uuid}",
            headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["data"]["user"]["uuid"]).to eq(user.uuid)
        expect(json["data"]["user"]["email_address"]).to eq(user.email_address)
      end

      it "returns 404 for non-existent user" do
        get "/api/v2/admin/users/invalid-uuid",
            headers: admin_api_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /api/v2/admin/users/find/:lookup" do
    let(:req_method) { :get }
    let(:req_path) { "/api/v2/admin/users/find/#{user.email_address}" }
    it_behaves_like "requires admin api authentication"

    context "with valid authentication" do
      it "finds user by UUID" do
        get "/api/v2/admin/users/find/#{user.uuid}",
            headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["data"]["user"]["uuid"]).to eq(user.uuid)
      end

      it "finds user by email address" do
        get "/api/v2/admin/users/find/#{user.email_address}",
            headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["data"]["user"]["email_address"]).to eq(user.email_address)
      end

      it "returns 404 for non-existent user" do
        get "/api/v2/admin/users/find/nonexistent@example.com",
            headers: admin_api_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v2/admin/users" do
    let(:req_method) { :post }
    let(:req_path) { "/api/v2/admin/users" }
    it_behaves_like "requires admin api authentication"

    context "with valid authentication" do
      it "creates a new user with password" do
        user_params = {
          email_address: "newuser@example.com",
          first_name: "John",
          last_name: "Doe",
          password: "SecurePassword123!"
        }

        post "/api/v2/admin/users",
             params: user_params,
             headers: admin_api_headers

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["data"]["user"]["email_address"]).to eq("newuser@example.com")
        expect(json["data"]["user"]["first_name"]).to eq("John")
        expect(json["data"]["user"]["last_name"]).to eq("Doe")
      end

      it "generates password if not provided" do
        user_params = {
          email_address: "generated-pass@example.com",
          first_name: "Gen",
          last_name: "Pass"
        }

        post "/api/v2/admin/users",
             params: user_params,
             headers: admin_api_headers

        puts "DEBUG USER CREATE BODY: #{response.body}" if response.status == 422
        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["data"]["user"]["email_address"]).to eq("generated-pass@example.com")
      end

      it "returns validation error for missing email" do
        post "/api/v2/admin/users",
             params: { password: "SecurePassword123!" },
             headers: admin_api_headers

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns validation error for duplicate email" do
        post "/api/v2/admin/users",
             params: { email_address: user.email_address },
             headers: admin_api_headers

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /api/v2/admin/users/:id" do
    let(:req_method) { :patch }
    let(:req_path) { "/api/v2/admin/users/#{user.uuid}" }
    it_behaves_like "requires admin api authentication"

    context "with valid authentication" do
      it "updates user details" do
        patch "/api/v2/admin/users/#{user.uuid}",
              params: { first_name: "Updated", last_name: "Name" },
              headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["data"]["user"]["first_name"]).to eq("Updated")
        expect(json["data"]["user"]["last_name"]).to eq("Name")
      end

      it "updates user password" do
        patch "/api/v2/admin/users/#{user.uuid}",
              params: { password: "NewPassword123!" },
              headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.authenticate("NewPassword123!")).to be_truthy
      end

      it "returns 404 for non-existent user" do
        patch "/api/v2/admin/users/invalid-uuid",
              params: { first_name: "Updated" },
              headers: admin_api_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v2/admin/users/:id" do
    let(:req_method) { :delete }
    let(:req_path) { "/api/v2/admin/users/#{user.uuid}" }
    it_behaves_like "requires admin api authentication"

    context "with valid authentication" do
      it "deletes the user" do
        delete "/api/v2/admin/users/#{user.uuid}",
               headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        expect(User.find_by(uuid: user.uuid)).to be_nil
      end

      it "returns 404 for non-existent user" do
        delete "/api/v2/admin/users/invalid-uuid",
               headers: admin_api_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
