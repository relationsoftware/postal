# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - IP Pools", type: :request do
  include_context "admin api authentication"

  describe "GET /api/v2/admin/ip_pools" do
    let!(:pool1) { create(:ip_pool, name: "Pool Alpha", default: false) }
    let!(:pool2) { create(:ip_pool, name: "Pool Beta", default: true) }

    context "with valid authentication" do
      it "returns a list of IP pools" do
        get "/api/v2/admin/ip_pools", headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["ip_pools"].length).to eq(2)
      end

      it "includes pool attributes" do
        get "/api/v2/admin/ip_pools", headers: auth_headers
        pool_data = json_response["data"]["ip_pools"].find { |p| p["name"] == "Pool Beta" }
        expect(pool_data).to include(
          "uuid" => pool2.uuid,
          "name" => "Pool Beta",
          "default" => true
        )
      end

      it "includes pagination info" do
        get "/api/v2/admin/ip_pools", headers: auth_headers
        expect(json_response["data"]["pagination"]).to include("page", "per_page")
      end
    end
  end

  describe "GET /api/v2/admin/ip_pools/:id" do
    let!(:ip_pool) { create(:ip_pool, name: "Test Pool") }
    let!(:ip_address) { create(:ip_address, ip_pool: ip_pool) }

    context "with valid authentication" do
      it "returns pool details" do
        get "/api/v2/admin/ip_pools/#{ip_pool.uuid}", headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["ip_pool"]["name"]).to eq("Test Pool")
        expect(json_response["data"]["ip_pool"]["uuid"]).to eq(ip_pool.uuid)
      end

      it "includes IP addresses in details" do
        get "/api/v2/admin/ip_pools/#{ip_pool.uuid}", headers: auth_headers
        expect(json_response["data"]["ip_pool"]["ip_addresses"]).to be_an(Array)
        expect(json_response["data"]["ip_pool"]["ip_addresses"].first["ipv4"]).to eq(ip_address.ipv4)
      end

      it "returns 404 for non-existent pool" do
        get "/api/v2/admin/ip_pools/non-existent-uuid", headers: auth_headers
        expect(response.status).to eq(404)
        expect_error("NotFound", status: 404)
      end
    end
  end

  describe "POST /api/v2/admin/ip_pools" do
    context "with valid authentication" do
      it "creates a new IP pool" do
        expect do
          post "/api/v2/admin/ip_pools",
               params: { name: "New Pool", default: false }.to_json,
               headers: json_headers
        end.to change(IPPool, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["ip_pool"]["name"]).to eq("New Pool")
        expect(json_response["data"]["ip_pool"]["default"]).to eq(false)
        expect(json_response["data"]["ip_pool"]["uuid"]).to be_present
      end

      it "creates a default pool" do
        post "/api/v2/admin/ip_pools",
             params: { name: "Default Pool", default: true }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["ip_pool"]["default"]).to eq(true)
      end
    end
  end

  describe "PATCH /api/v2/admin/ip_pools/:id" do
    let!(:ip_pool) { create(:ip_pool, name: "Original Name", default: false) }

    context "with valid authentication" do
      it "updates the pool name" do
        patch "/api/v2/admin/ip_pools/#{ip_pool.uuid}",
              params: { name: "Updated Name" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["ip_pool"]["name"]).to eq("Updated Name")
        expect(ip_pool.reload.name).to eq("Updated Name")
      end

      it "updates the default flag" do
        patch "/api/v2/admin/ip_pools/#{ip_pool.uuid}",
              params: { default: true }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(ip_pool.reload.default).to eq(true)
      end

      it "returns 404 for non-existent pool" do
        patch "/api/v2/admin/ip_pools/non-existent-uuid",
              params: { name: "Updated" }.to_json,
              headers: json_headers

        expect(response.status).to eq(404)
      end
    end
  end

  describe "DELETE /api/v2/admin/ip_pools/:id" do
    let!(:ip_pool) { create(:ip_pool, name: "To Delete") }

    context "with valid authentication" do
      it "deletes the pool" do
        expect do
          delete "/api/v2/admin/ip_pools/#{ip_pool.uuid}", headers: auth_headers
        end.to change(IPPool, :count).by(-1)

        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["deleted"]).to eq(true)
      end

      it "returns 404 for non-existent pool" do
        delete "/api/v2/admin/ip_pools/non-existent-uuid", headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end
end
