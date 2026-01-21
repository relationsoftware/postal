# frozen_string_literal: true

require "rails_helper"
require_relative "shared_context"

RSpec.describe "Admin API - Routes", type: :request do
  include_context "admin api authentication"

  let!(:organization) { create(:organization) }
  let!(:server) { create(:server, organization: organization) }

  describe "GET /api/v2/admin/organizations/:org/servers/:server/routes" do
    let!(:route1) { create(:route, server: server, name: "*@alpha.com") }
    let!(:route2) { create(:route, server: server, name: "*@beta.com") }

    context "with valid authentication" do
      it "returns a list of routes" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/routes",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["routes"].length).to eq(2)
      end

      it "includes route attributes" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/routes",
            headers: auth_headers
        route_data = json_response["data"]["routes"].find { |r| r["name"] == "*@alpha.com" }
        expect(route_data).to include(
          "id" => route1.id,
          "uuid" => route1.uuid,
          "mode" => route1.mode
        )
      end
    end
  end

  describe "GET /api/v2/admin/organizations/:org/servers/:server/routes/:uuid" do
    let!(:http_endpoint) { create(:http_endpoint, server: server) }
    let!(:route) { create(:route, server: server, name: "*@test.com", endpoint: http_endpoint) }

    context "with valid authentication" do
      it "returns route details with endpoint" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/routes/#{route.uuid}",
            headers: auth_headers
        expect(response.status).to eq(200)
        expect_success
        expect(json_response["data"]["route"]["name"]).to eq("*@test.com")
        expect(json_response["data"]["route"]["endpoint"]).to be_present
        expect(json_response["data"]["route"]["endpoint"]["uuid"]).to eq(http_endpoint.uuid)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:org/servers/:server/routes" do
    context "with valid authentication" do
      it "creates a new route" do
        expect {
          post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/routes",
               params: { name: "*@new.com", mode: "Endpoint" }.to_json,
               headers: json_headers
        }.to change(Route, :count).by(1)

        expect(response.status).to eq(201)
        expect_success
        expect(json_response["data"]["route"]["name"]).to eq("*@new.com")
      end

      it "creates route with endpoint" do
        http_endpoint = create(:http_endpoint, server: server)

        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/routes",
             params: {
               name: "*@endpoint.com",
               mode: "Endpoint",
               endpoint_uuid: http_endpoint.uuid,
               endpoint_type: "HTTPEndpoint"
             }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        route = Route.find_by(name: "*@endpoint.com")
        expect(route.endpoint).to eq(http_endpoint)
      end

      it "creates route with spam_mode" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/routes",
             params: { name: "*@spam.com", mode: "Bounce", spam_mode: "Quarantine" }.to_json,
             headers: json_headers

        expect(response.status).to eq(201)
        expect(json_response["data"]["route"]["spam_mode"]).to eq("Quarantine")
      end
    end
  end

  describe "PATCH /api/v2/admin/organizations/:org/servers/:server/routes/:uuid" do
    let!(:route) { create(:route, server: server, name: "*@original.com", mode: "Bounce") }

    context "with valid authentication" do
      it "updates the route" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/routes/#{route.uuid}",
              params: { name: "*@updated.com" }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect_success
        expect(route.reload.name).to eq("*@updated.com")
      end

      it "updates route endpoint" do
        http_endpoint = create(:http_endpoint, server: server)

        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/routes/#{route.uuid}",
              params: {
                mode: "Endpoint",
                endpoint_uuid: http_endpoint.uuid,
                endpoint_type: "HTTPEndpoint"
              }.to_json,
              headers: json_headers

        expect(response.status).to eq(200)
        expect(route.reload.endpoint).to eq(http_endpoint)
      end
    end
  end

  describe "DELETE /api/v2/admin/organizations/:org/servers/:server/routes/:uuid" do
    let!(:route) { create(:route, server: server, name: "*@delete.com") }

    context "with valid authentication" do
      it "deletes the route" do
        expect {
          delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/routes/#{route.uuid}",
                 headers: auth_headers
        }.to change(Route, :count).by(-1)

        expect(response.status).to eq(200)
        expect(json_response["data"]["deleted"]).to eq(true)
      end
    end
  end
end
