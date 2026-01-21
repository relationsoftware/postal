# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - IP Pools", type: :request do
  include_context "admin api authentication"

  describe "GET /api/v2/admin/ip_pools" do
    let!(:pool1) { create(:ip_pool, name: "Pool Alpha") }
    let!(:pool2) { create(:ip_pool, name: "Pool Beta") }

    context "with valid authentication" do
      it "returns a list of IP pools" do
        get "/api/v2/admin/ip_pools", headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["ip_pools"].length).to eq(2)
      end

      it "includes pool attributes" do
        get "/api/v2/admin/ip_pools", headers: auth_headers
        pool_data = json_response["data"]["ip_pools"].find { |p| p["name"] == "Pool Alpha" }
        expect(pool_data).to include(
          "id" => pool1.id,
          "uuid" => pool1.uuid,
          "default" => pool1.default
        )
      end
    end
  end

  describe "GET /api/v2/admin/ip_pools/:uuid" do
    let!(:ip_pool) { create(:ip_pool, name: "Test Pool") }

    context "with valid authentication" do
      it "returns pool details" do
        get "/api/v2/admin/ip_pools/#{ip_pool.uuid}", headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["ip_pool"]["name"]).to eq("Test Pool")
      end

      it "includes IP addresses" do
        ip = create(:ip_address, ip_pool: ip_pool, ipv4: "192.168.1.1")

        get "/api/v2/admin/ip_pools/#{ip_pool.uuid}", headers: auth_headers
        expect(json_response["data"]["ip_pool"]["ip_addresses"]).to be_an(Array)
        expect(json_response["data"]["ip_pool"]["ip_addresses"].first["ipv4"]).to eq("192.168.1.1")
      end

      it "returns 404 for non-existent pool" do
        get "/api/v2/admin/ip_pools/non-existent-uuid", headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /api/v2/admin/ip_pools" do
    context "with valid authentication" do
      it "creates a new IP pool" do
        expect {
          post "/api/v2/admin/ip_pools",
               params: { name: "New Pool" }.to_json,
               headers: json_headers
        }.to change(IPPool, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["ip_pool"]["name"]).to eq("New Pool")
      end

      it "creates default pool" do
        post "/api/v2/admin/ip_pools",
             params: { name: "Default Pool", default: true }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["ip_pool"]["default"]).to eq(true)
      end

      it "returns validation error for missing name" do
        post "/api/v2/admin/ip_pools",
             params: { name: "" }.to_json,
             headers: json_headers

        expect(response.status).to eq(422)
        expect_error("ValidationError", status: 422)
      end
    end
  end

  describe "PATCH /api/v2/admin/ip_pools/:uuid" do
    let!(:ip_pool) { create(:ip_pool, name: "Original Pool") }

    context "with valid authentication" do
      it "updates the pool" do
        patch "/api/v2/admin/ip_pools/#{ip_pool.uuid}",
              params: { name: "Updated Pool" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect_success
        expect(ip_pool.reload.name).to eq("Updated Pool")
      end
    end
  end

  describe "DELETE /api/v2/admin/ip_pools/:uuid" do
    let!(:ip_pool) { create(:ip_pool) }

    context "with valid authentication" do
      it "deletes the pool" do
        expect {
          delete "/api/v2/admin/ip_pools/#{ip_pool.uuid}", headers: auth_headers
        }.to change(IPPool, :count).by(-1)

        expect(response.status).to eq(200)
        expect(json_response["data"]["deleted"]).to eq(true)
      end
    end
  end

  describe "IP Addresses" do
    let!(:ip_pool) { create(:ip_pool) }

    describe "GET /api/v2/admin/ip_pools/:pool/ip_addresses" do
      let!(:ip1) { create(:ip_address, ip_pool: ip_pool, ipv4: "10.0.0.1") }
      let!(:ip2) { create(:ip_address, ip_pool: ip_pool, ipv4: "10.0.0.2") }

      it "returns a list of IP addresses" do
        get "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses", headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["ip_addresses"].length).to eq(2)
      end
    end

    describe "POST /api/v2/admin/ip_pools/:pool/ip_addresses" do
      it "creates a new IP address" do
        expect {
          post "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses",
               params: {
                 ipv4: "192.168.1.100",
                 hostname: "mail.example.com",
                 priority: 10
               }.to_json,
               headers: json_headers
        }.to change(IPAddress, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["ip_address"]["ipv4"]).to eq("192.168.1.100")
        expect(json_response["data"]["ip_address"]["hostname"]).to eq("mail.example.com")
      end

      it "creates IP address with IPv6" do
        post "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses",
             params: {
               ipv4: "10.0.0.1",
               ipv6: "2001:db8::1",
               hostname: "mail.example.com"
             }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["ip_address"]["ipv6"]).to eq("2001:db8::1")
      end
    end

    describe "PATCH /api/v2/admin/ip_pools/:pool/ip_addresses/:id" do
      let!(:ip_address) { create(:ip_address, ip_pool: ip_pool, hostname: "old.example.com") }

      it "updates the IP address" do
        patch "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses/#{ip_address.id}",
              params: { hostname: "new.example.com", priority: 20 }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(ip_address.reload.hostname).to eq("new.example.com")
        expect(ip_address.priority).to eq(20)
      end
    end

    describe "DELETE /api/v2/admin/ip_pools/:pool/ip_addresses/:id" do
      let!(:ip_address) { create(:ip_address, ip_pool: ip_pool) }

      it "deletes the IP address" do
        expect {
          delete "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses/#{ip_address.id}",
                 headers: auth_headers
        }.to change(IPAddress, :count).by(-1)

        expect(response.status).to eq(200)
      end
    end
  end
end
