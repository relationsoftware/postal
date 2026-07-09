# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - Track Domains", type: :request do
  include_context "admin api authentication"

  let!(:organization) { create(:organization) }
  let!(:server) { create(:server, organization: organization) }
  let!(:domain) { create(:domain, server: server, owner: organization) }

  describe "GET /api/v2/admin/organizations/:org/servers/:server/track_domains" do
    let!(:track_domain1) { create(:track_domain, server: server, name: "click") }
    let!(:track_domain2) { create(:track_domain, server: server, name: "track") }

    context "with valid authentication" do
      it "returns a list of track domains" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["track_domains"]).to be_an(Array)
        expect(json_response["data"]["track_domains"].length).to eq(2)
      end

      it "includes track domain attributes" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains",
            headers: auth_headers
        td_data = json_response["data"]["track_domains"].first
        expect(td_data).to include("uuid", "name", "ssl_enabled", "track_clicks", "track_loads")
      end

      it "includes pagination info" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains",
            headers: auth_headers
        expect(json_response["data"]["pagination"]).to include("page", "per_page")
      end
    end
  end

  describe "GET /api/v2/admin/organizations/:org/servers/:server/track_domains/:id" do
    let!(:track_domain) { create(:track_domain, server: server, name: "tracking") }

    context "with valid authentication" do
      it "returns track domain details" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains/#{track_domain.uuid}",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["track_domain"]["name"]).to eq("tracking")
        expect(json_response["data"]["track_domain"]["uuid"]).to eq(track_domain.uuid)
      end

      it "includes DNS details" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains/#{track_domain.uuid}",
            headers: auth_headers
        expect(json_response["data"]["track_domain"]["dns"]).to include("status")
      end

      it "returns 404 for non-existent track domain" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains/non-existent-uuid",
            headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:org/servers/:server/track_domains" do
    context "with valid authentication" do
      it "creates a new track domain" do
        expect do
          post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains",
               params: { name: "newtrack", domain_id: domain.id, track_clicks: true, track_loads: true }.to_json,
               headers: json_headers
        end.to change(TrackDomain, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["track_domain"]["name"]).to eq("newtrack")
      end

      it "creates track domain with SSL enabled" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains",
             params: { name: "secure", domain_id: domain.id, ssl_enabled: true }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["track_domain"]["ssl_enabled"]).to eq(true)
      end

      it "creates track domain with tracking options disabled" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains",
             params: { name: "notrack", domain_id: domain.id, track_clicks: false, track_loads: false }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["track_domain"]["track_clicks"]).to eq(false)
        expect(json_response["data"]["track_domain"]["track_loads"]).to eq(false)
      end
    end
  end

  describe "PATCH /api/v2/admin/organizations/:org/servers/:server/track_domains/:id" do
    let!(:track_domain) { create(:track_domain, server: server, name: "original", track_clicks: true) }

    context "with valid authentication" do
      it "updates the track domain name" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains/#{track_domain.uuid}",
              params: { name: "updated" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["track_domain"]["name"]).to eq("updated")
        expect(track_domain.reload.name).to eq("updated")
      end

      it "updates tracking options" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains/#{track_domain.uuid}",
              params: { track_clicks: false }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(track_domain.reload.track_clicks).to eq(false)
      end

      it "returns 404 for non-existent track domain" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains/non-existent-uuid",
              params: { name: "updated" }.to_json,
              headers: json_headers

        expect(response.status).to eq(404)
      end
    end
  end

  describe "DELETE /api/v2/admin/organizations/:org/servers/:server/track_domains/:id" do
    let!(:track_domain) { create(:track_domain, server: server) }

    context "with valid authentication" do
      it "deletes the track domain" do
        expect do
          delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains/#{track_domain.uuid}",
                 headers: auth_headers
        end.to change(TrackDomain, :count).by(-1)

        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["deleted"]).to eq(true)
      end

      it "returns 404 for non-existent track domain" do
        delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains/non-existent-uuid",
               headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:org/servers/:server/track_domains/:id/check" do
    let!(:track_domain) { create(:track_domain, server: server) }

    context "with valid authentication" do
      before do
        allow_any_instance_of(TrackDomain).to receive(:check_dns)
      end

      it "checks DNS for the track domain" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains/#{track_domain.uuid}/check",
             headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["track_domain"]["dns"]).to include("status")
      end

      it "returns 404 for non-existent track domain" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/track_domains/non-existent-uuid/check",
             headers: auth_headers
        expect(response.status).to eq(404)
      end
    end
  end
end
