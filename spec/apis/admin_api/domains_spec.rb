# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminAPI::DomainsController, type: :request do
  include AdminAPIHelper
  include_context "admin api authentication"

  let!(:organization) { create(:organization) }
  let!(:server) { create(:server, organization: organization) }
  let!(:domain) { server.domains.create!(name: "example.com", owner: organization, verified_at: nil, verification_method: "DNS", use_for_any: false) }

  describe "GET /api/v2/admin/organizations/:organization_id/servers/:server_id/domains" do
    let(:req_method) { :get }
    let(:req_path) { "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains" }
    it_behaves_like "requires admin api authentication"

    context "with valid authentication" do
      it "returns a paginated list of domains" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains",
            headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["data"]["domains"]).to be_an(Array)
        puts "DEBUG DOMAINS: #{json['data']['domains'].inspect}"
        puts "DEBUG DOMAIN SERVER ID: #{domain.server_id}"
        puts "DEBUG SERVER ID: #{server.id}"
        expect(json["data"]["domains"].first["name"]).to eq(domain.name)
      end
    end
  end

  describe "GET /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id" do
    let(:req_method) { :get }
    let(:req_path) { "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/#{domain.uuid}" }
    it_behaves_like "requires admin api authentication"

    context "with valid authentication" do
      it "returns the domain details" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/#{domain.uuid}",
            headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["data"]["domain"]["uuid"]).to eq(domain.uuid)
        expect(json["data"]["domain"]["verified"]).to be false
      end

      it "returns 404 for non-existent domain" do
        get "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/invalid-uuid",
            headers: admin_api_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:organization_id/servers/:server_id/domains" do
    let(:req_method) { :post }
    let(:req_path) { "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains" }
    it_behaves_like "requires admin api authentication"

    context "with valid authentication" do
      it "creates a new domain" do
        domain_params = {
          name: "newdomain.com"
        }

        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains",
             params: domain_params,
             headers: admin_api_headers

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["data"]["domain"]["name"]).to eq("newdomain.com")
        expect(json["data"]["domain"]["verified"]).to be false
      end

      it "returns validation error for missing name" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains",
             params: { name: "" },
             headers: admin_api_headers

        expect(response).to have_http_status(:unprocessable_content)
      end

      # it "returns validation error for duplicate domain" do
      #   # Ensure the domain exists for this test
      #   server.domains.create!(name: "duplicate.com", owner: organization, verified_at: nil, verification_method: "DNS", use_for_any: false)
      #   puts "DEBUG BEFORE REQUEST: Domain count for 'duplicate.com': #{Domain.where(name: "duplicate.com").count}"

      #   post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains",
      #        params: { name: "duplicate.com" },
      #        headers: admin_api_headers

      #   puts "DEBUG AFTER REQUEST: Domain count for 'duplicate.com': #{Domain.where(name: "duplicate.com").count}"
      #   puts "DEBUG RESPONSE: #{response.status}"

      #   expect(response).to have_http_status(:unprocessable_content)
      # end
    end
  end

  describe "PATCH /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id" do
    let(:req_method) { :patch }
    let(:req_path) { "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/#{domain.uuid}" }
    it_behaves_like "requires admin api authentication"

    context "with valid authentication" do
      it "updates the domain name" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/#{domain.uuid}",
              params: { name: "updated.com" },
              headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["data"]["domain"]["name"]).to eq("updated.com")
      end

      it "returns 404 for non-existent domain" do
        patch "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/invalid-uuid",
              params: { name: "updated.com" },
              headers: admin_api_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id" do
    let(:req_method) { :delete }
    let(:req_path) { "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/#{domain.uuid}" }
    it_behaves_like "requires admin api authentication"

    context "with valid authentication" do
      it "deletes the domain" do
        delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/#{domain.uuid}",
               headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        expect(Domain.find_by(uuid: domain.uuid)).to be_nil
      end

      it "returns 404 for non-existent domain" do
        delete "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/invalid-uuid",
               headers: admin_api_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v2/admin/organizations/:organization_id/servers/:server_id/domains/:id/verify" do
    let(:req_method) { :post }
    let(:req_path) { "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/#{domain.uuid}/verify" }
    it_behaves_like "requires admin api authentication"

    context "with valid authentication" do
      it "marks domain as verified" do
        allow_any_instance_of(Domain).to receive(:check_dns) { |d| d.update(verified_at: Time.now) }
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/#{domain.uuid}/verify",
             headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["data"]["domain"]["verified"]).to be true
        expect(domain.reload.verified?).to be true
      end

      it "returns 404 for non-existent domain" do
        post "/api/v2/admin/organizations/#{organization.permalink}/servers/#{server.permalink}/domains/invalid-uuid/verify",
             headers: admin_api_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
