# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - Webhooks", type: :request do
  include_context "admin api authentication"

  let!(:organization) { create(:organization) }
  let!(:server) { create(:server, organization: organization) }

  describe "GET /api/v2/admin/organizations/:org/servers/:server/webhooks" do
    let!(:webhook1) { create(:webhook, server: server, name: "Webhook 1") }
    let!(:webhook2) { create(:webhook, server: server, name: "Webhook 2") }

    context "with valid authentication" do
      it "returns a list of webhooks" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/webhooks",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["webhooks"].length).to eq(2)
      end

      it "includes webhook attributes" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/webhooks",
            headers: auth_headers
        webhook_data = json_response["data"]["webhooks"].find { |w| w["name"] == "Webhook 1" }
        expect(webhook_data).to include(
          "id" => webhook1.id,
          "uuid" => webhook1.uuid,
          "url" => webhook1.url,
          "enabled" => webhook1.enabled
        )
      end
    end
  end

  describe "GET /api/v2/admin/organizations/:org/servers/:server/webhooks/:uuid" do
    let!(:webhook) { create(:webhook, server: server, name: "Test Webhook", all_events: true) }

    context "with valid authentication" do
      it "returns webhook details with events" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/webhooks/#{webhook.uuid}",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["webhook"]["name"]).to eq("Test Webhook")
        expect(json_response["data"]["webhook"]["all_events"]).to eq(true)
        expect(json_response["data"]["webhook"]["events"]).to be_an(Array)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:org/servers/:server/webhooks" do
    context "with valid authentication" do
      it "creates a new webhook" do
        expect {
          post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/webhooks",
               params: {
                 name: "New Webhook",
                 url: "https://example.com/webhook",
                 enabled: true,
                 all_events: true
               }.to_json,
               headers: json_headers
        }.to change(Webhook, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["webhook"]["name"]).to eq("New Webhook")
        expect(json_response["data"]["webhook"]["url"]).to eq("https://example.com/webhook")
      end

      it "creates webhook with specific events" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/webhooks",
             params: {
               name: "Event Webhook",
               url: "https://example.com/events",
               all_events: false,
               events: ["MessageSent", "MessageDelivered", "MessageBounced"]
             }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        webhook = Webhook.find_by(name: "Event Webhook")
        expect(webhook.all_events).to eq(false)
      end

      it "creates webhook with signing enabled" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/webhooks",
             params: {
               name: "Signed Webhook",
               url: "https://example.com/signed",
               sign: true
             }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["webhook"]["sign"]).to eq(true)
      end

      it "returns validation error for missing url" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/webhooks",
             params: { name: "No URL" }.to_json,
             headers: json_headers

        expect(response.status).to eq(422)
        expect_error("ValidationError", status: 422)
      end
    end
  end

  describe "PATCH /api/v2/admin/organizations/:org/servers/:server/webhooks/:uuid" do
    let!(:webhook) { create(:webhook, server: server, name: "Original", url: "https://old.com") }

    context "with valid authentication" do
      it "updates the webhook" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/webhooks/#{webhook.uuid}",
              params: { name: "Updated", url: "https://new.com" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect_success
        expect(webhook.reload.name).to eq("Updated")
        expect(webhook.url).to eq("https://new.com")
      end
    end
  end

  describe "DELETE /api/v2/admin/organizations/:org/servers/:server/webhooks/:uuid" do
    let!(:webhook) { create(:webhook, server: server) }

    context "with valid authentication" do
      it "deletes the webhook" do
        expect {
          delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/webhooks/#{webhook.uuid}",
                 headers: auth_headers
        }.to change(Webhook, :count).by(-1)

        expect(response.status).to eq(200)
        expect(json_response["data"]["deleted"]).to eq(true)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:org/servers/:server/webhooks/:uuid/enable" do
    let!(:webhook) { create(:webhook, server: server, enabled: false) }

    context "with valid authentication" do
      it "enables the webhook" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/webhooks/#{webhook.uuid}/enable",
             headers: auth_headers

        expect(response.status).to eq(200)
        expect_success
        expect(webhook.reload.enabled).to eq(true)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:org/servers/:server/webhooks/:uuid/disable" do
    let!(:webhook) { create(:webhook, server: server, enabled: true) }

    context "with valid authentication" do
      it "disables the webhook" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/webhooks/#{webhook.uuid}/disable",
             headers: auth_headers

        expect(response.status).to eq(200)
        expect_success
        expect(webhook.reload.enabled).to eq(false)
      end
    end
  end
end
