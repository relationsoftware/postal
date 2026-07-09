# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - Suppressions", type: :request do
  include_context "admin api authentication"

  let!(:organization) { create(:organization) }
  let!(:server) { create(:server, organization: organization) }

  # NOTE: Suppressions are stored in per-server message databases.
  # These tests mock the suppression_list interface.

  describe "GET /api/v2/admin/organizations/:org/servers/:server/suppressions" do
    context "with valid authentication" do
      let(:mock_suppressions) do
        [
          { "id" => 1, "type" => "recipient", "address" => "bounced@example.com", "reason" => "Hard bounce", "timestamp" => Time.now.to_i },
          { "id" => 2, "type" => "recipient", "address" => "spam@example.com", "reason" => "Spam complaint", "timestamp" => Time.now.to_i },
        ]
      end

      before do
        message_db = double("MessageDB")
        suppression_list = double("SuppressionList")
        allow(suppression_list).to receive(:all_with_pagination).and_return({
          records: mock_suppressions,
          total: 2,
          total_pages: 1,
          per_page: 25
        })
        allow(message_db).to receive(:suppression_list).and_return(suppression_list)
        allow_any_instance_of(Server).to receive(:message_db).and_return(message_db)
      end

      it "returns a list of suppressions" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/suppressions",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["suppressions"]).to be_an(Array)
        expect(json_response["data"]["suppressions"].length).to eq(2)
      end

      it "includes suppression attributes" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/suppressions",
            headers: auth_headers
        suppression = json_response["data"]["suppressions"].first
        expect(suppression).to include("type", "address", "reason")
      end

      it "includes pagination info" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/suppressions",
            headers: auth_headers
        expect(json_response["data"]["pagination"]).to include("page", "total", "total_pages", "per_page")
      end
    end

    context "with invalid organization" do
      it "returns 404" do
        get "/api/v2/admin/organizations/non-existent/servers/#{server.permalink}/suppressions",
            headers: auth_headers
        expect(response.status).to eq(404)
      end
    end

    context "with invalid server" do
      it "returns 404" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/non-existent/suppressions",
            headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:org/servers/:server/suppressions" do
    context "with valid authentication" do
      before do
        message_db = double("MessageDB")
        suppression_list = double("SuppressionList")
        allow(suppression_list).to receive(:add)
        allow(message_db).to receive(:suppression_list).and_return(suppression_list)
        allow_any_instance_of(Server).to receive(:message_db).and_return(message_db)
      end

      it "creates a recipient suppression" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/suppressions",
             params: { type: "recipient", address: "blocked@example.com", reason: "Manual block" }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["suppression"]["address"]).to eq("blocked@example.com")
        expect(json_response["data"]["suppression"]["reason"]).to eq("Manual block")
      end

      it "creates suppression with default type" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/suppressions",
             params: { address: "blocked2@example.com" }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["suppression"]["type"]).to eq("recipient")
      end

      it "creates suppression with expiry days" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/suppressions",
             params: { address: "temp@example.com", days: 30 }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
      end

      it "returns error without address" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/suppressions",
             params: { reason: "No address provided" }.to_json,
             headers: json_headers

        expect(response.status).to eq(422)
        expect_error("ValidationError", status: 422)
      end
    end
  end

  describe "DELETE /api/v2/admin/organizations/:org/servers/:server/suppressions/:address" do
    context "with valid authentication and existing suppression" do
      before do
        message_db = double("MessageDB")
        suppression_list = double("SuppressionList")
        allow(suppression_list).to receive(:remove).with(:recipient, "blocked@example.com").and_return(true)
        allow(message_db).to receive(:suppression_list).and_return(suppression_list)
        allow_any_instance_of(Server).to receive(:message_db).and_return(message_db)
      end

      it "removes the suppression" do
        delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/suppressions/blocked@example.com",
               headers: auth_headers

        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["deleted"]).to eq(true)
      end

      it "removes suppression with type parameter" do
        delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/suppressions/blocked@example.com",
               params: { type: "recipient" },
               headers: auth_headers

        expect(response.status).to eq(200)
      end
    end

    context "with non-existent suppression" do
      before do
        message_db = double("MessageDB")
        suppression_list = double("SuppressionList")
        allow(suppression_list).to receive(:remove).and_return(false)
        allow(message_db).to receive(:suppression_list).and_return(suppression_list)
        allow_any_instance_of(Server).to receive(:message_db).and_return(message_db)
      end

      it "returns 404" do
        delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/suppressions/nonexistent@example.com",
               headers: auth_headers

        expect(response.status).to eq(404)
        expect_error("NotFound", status: 404)
      end
    end
  end
end
