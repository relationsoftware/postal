# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - IP Addresses", type: :request do
  include_context "admin api authentication"

  let!(:ip_pool) { create(:ip_pool, name: "Test Pool") }

  describe "GET /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses" do
    let!(:ip1) { create(:ip_address, ip_pool: ip_pool, ipv4: "10.0.0.1") }
    let!(:ip2) { create(:ip_address, ip_pool: ip_pool, ipv4: "10.0.0.2") }

    context "with valid authentication" do
      it "returns a list of IP addresses" do
        get "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses", headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["ip_addresses"].length).to eq(2)
      end

      it "includes IP address attributes" do
        get "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses", headers: auth_headers
        ip_data = json_response["data"]["ip_addresses"].find { |ip| ip["ipv4"] == "10.0.0.1" }
        expect(ip_data).to include(
          "ipv4" => "10.0.0.1",
          "hostname" => ip1.hostname
        )
      end

      it "includes pagination info" do
        get "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses", headers: auth_headers
        expect(json_response["data"]["pagination"]).to include("page", "per_page")
      end

      it "returns 404 for non-existent pool" do
        get "/api/v2/admin/ip_pools/non-existent-uuid/ip_addresses", headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end

  describe "GET /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses/:id" do
    let!(:ip_address) { create(:ip_address, ip_pool: ip_pool, ipv4: "10.0.0.100") }

    context "with valid authentication" do
      it "returns IP address details" do
        get "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses/#{ip_address.id}",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["ip_address"]["ipv4"]).to eq("10.0.0.100")
      end

      it "returns 404 for non-existent address" do
        get "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses/99999",
            headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses" do
    context "with valid authentication" do
      it "creates a new IP address" do
        expect do
          post "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses",
               params: { ipv4: "192.168.1.1", hostname: "mail.example.com" }.to_json,
               headers: json_headers
        end.to change(IPAddress, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["ip_address"]["ipv4"]).to eq("192.168.1.1")
        expect(json_response["data"]["ip_address"]["hostname"]).to eq("mail.example.com")
      end

      it "creates IP address with IPv6" do
        post "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses",
             params: { ipv4: "192.168.1.2", ipv6: "2001:db8::1", hostname: "mail2.example.com" }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["ip_address"]["ipv6"]).to eq("2001:db8::1")
      end

      it "creates IP address with priority" do
        post "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses",
             params: { ipv4: "192.168.1.3", hostname: "mail3.example.com", priority: 10 }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["ip_address"]["priority"]).to eq(10)
      end
    end
  end

  describe "PATCH /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses/:id" do
    let!(:ip_address) { create(:ip_address, ip_pool: ip_pool, hostname: "original.example.com") }

    context "with valid authentication" do
      it "updates the IP address hostname" do
        patch "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses/#{ip_address.id}",
              params: { hostname: "updated.example.com" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["ip_address"]["hostname"]).to eq("updated.example.com")
        expect(ip_address.reload.hostname).to eq("updated.example.com")
      end

      it "updates the priority" do
        patch "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses/#{ip_address.id}",
              params: { priority: 5 }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(ip_address.reload.priority).to eq(5)
      end

      it "returns 404 for non-existent address" do
        patch "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses/99999",
              params: { hostname: "updated.example.com" }.to_json,
              headers: json_headers

        expect(response.status).to eq(404)
      end
    end
  end

  describe "DELETE /api/v2/admin/ip_pools/:ip_pool_id/ip_addresses/:id" do
    let!(:ip_address) { create(:ip_address, ip_pool: ip_pool) }

    context "with valid authentication" do
      it "deletes the IP address" do
        expect do
          delete "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses/#{ip_address.id}",
                 headers: auth_headers
        end.to change(IPAddress, :count).by(-1)

        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["deleted"]).to eq(true)
      end

      it "returns 404 for non-existent address" do
        delete "/api/v2/admin/ip_pools/#{ip_pool.uuid}/ip_addresses/99999",
               headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end
end
