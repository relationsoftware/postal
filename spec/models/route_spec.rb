# frozen_string_literal: true

require "rails_helper"

RSpec.describe Route, type: :model do
  let(:organization) { create(:organization) }
  let(:server) { create(:server, organization: organization) }
  let(:domain) { create(:domain, owner: server, verified_at: Time.now) }

  describe "associations" do
    it { should belong_to(:server) }
    it { should belong_to(:domain).optional }
    it { should belong_to(:endpoint).optional }
    it { should have_many(:additional_route_endpoints).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_inclusion_of(:spam_mode).in_array(Route::SPAM_MODES) }

    describe "name format" do
      it "accepts valid names" do
        %w[test user-name user.name user123 *].each do |name|
          route = build(:route, server: server, domain: domain, name: name)
          expect(route).to be_valid, "Expected '#{name}' to be valid"
        end
      end

      it "rejects invalid names" do
        %w[Test USER Name! name@domain].each do |name|
          route = build(:route, server: server, domain: domain, name: name)
          expect(route).not_to be_valid, "Expected '#{name}' to be invalid"
        end
      end

      it "accepts __returnpath__ as special name" do
        http_endpoint = create(:http_endpoint, server: server)
        route = build(:route, server: server, domain: nil, name: "__returnpath__", endpoint: http_endpoint, mode: "Endpoint")
        expect(route).to be_valid
      end
    end

    describe "endpoint presence" do
      it "requires endpoint when mode is Endpoint" do
        route = build(:route, server: server, domain: domain, mode: "Endpoint", endpoint: nil)
        expect(route).not_to be_valid
        expect(route.errors[:endpoint]).to include("can't be blank")
      end

      it "does not require endpoint for other modes" do
        %w[Accept Hold Bounce Reject].each do |mode|
          route = build(:route, server: server, domain: domain, mode: mode, endpoint: nil)
          expect(route).to be_valid, "Expected mode '#{mode}' to not require endpoint"
        end
      end
    end

    describe "domain validation" do
      it "requires domain for non-return-path routes" do
        route = build(:route, server: server, domain: nil, name: "test", mode: "Bounce")
        expect(route).not_to be_valid
        expect(route.errors[:domain_id]).to include("can't be blank")
      end

      it "does not require domain for return path routes" do
        http_endpoint = create(:http_endpoint, server: server)
        route = build(:route, server: server, domain: nil, name: "__returnpath__", endpoint: http_endpoint, mode: "Endpoint")
        expect(route).to be_valid
      end

      it "requires domain to be verified" do
        unverified_domain = create(:domain, owner: server, verified_at: nil)
        route = build(:route, server: server, domain: unverified_domain, mode: "Bounce")
        expect(route).not_to be_valid
        expect(route.errors[:domain]).to include("has not been verified yet")
      end

      it "requires domain to belong to server or organization" do
        other_server = create(:server)
        other_domain = create(:domain, owner: other_server, verified_at: Time.now)
        route = build(:route, server: server, domain: other_domain, mode: "Bounce")
        expect(route).not_to be_valid
        expect(route.errors[:domain]).to include("is invalid")
      end
    end

    describe "endpoint validation" do
      it "requires endpoint to belong to same server" do
        other_server = create(:server)
        other_endpoint = create(:http_endpoint, server: other_server)
        route = build(:route, server: server, domain: domain, mode: "Endpoint", endpoint: other_endpoint)
        expect(route).not_to be_valid
        expect(route.errors[:endpoint]).to include("is invalid")
      end
    end

    describe "name uniqueness" do
      it "prevents duplicate names on same domain" do
        create(:route, server: server, domain: domain, name: "test", mode: "Bounce")
        route = build(:route, server: server, domain: domain, name: "test", mode: "Bounce")
        expect(route).not_to be_valid
      end

      it "allows same name on different domains" do
        other_domain = create(:domain, owner: server, verified_at: Time.now)
        create(:route, server: server, domain: domain, name: "test", mode: "Bounce")
        route = build(:route, server: server, domain: other_domain, name: "test", mode: "Bounce")
        expect(route).to be_valid
      end
    end

    describe "return path route validation" do
      it "requires HTTP endpoint for return path routes" do
        smtp_endpoint = create(:smtp_endpoint, server: server)
        route = build(:route, server: server, domain: nil, name: "__returnpath__", endpoint: smtp_endpoint, mode: "Endpoint")
        expect(route).not_to be_valid
        expect(route.errors[:base]).to include("Return path routes must point to an HTTP endpoint")
      end

      it "accepts HTTP endpoint for return path routes" do
        http_endpoint = create(:http_endpoint, server: server)
        route = build(:route, server: server, domain: nil, name: "__returnpath__", endpoint: http_endpoint, mode: "Endpoint")
        expect(route).to be_valid
      end
    end
  end

  describe "constants" do
    it "defines valid modes" do
      expect(Route::MODES).to eq(%w[Endpoint Accept Hold Bounce Reject])
    end

    it "defines valid spam modes" do
      expect(Route::SPAM_MODES).to eq(%w[Mark Quarantine Fail])
    end

    it "defines valid endpoint types" do
      expect(Route::ENDPOINT_TYPES).to eq(%w[SMTPEndpoint HTTPEndpoint AddressEndpoint])
    end
  end

  describe "#return_path?" do
    it "returns true for __returnpath__ name" do
      route = build(:route, name: "__returnpath__")
      expect(route.return_path?).to be true
    end

    it "returns false for other names" do
      route = build(:route, name: "test")
      expect(route.return_path?).to be false
    end
  end

  describe "#wildcard?" do
    it "returns true for * name" do
      route = build(:route, name: "*")
      expect(route.wildcard?).to be true
    end

    it "returns false for other names" do
      route = build(:route, name: "test")
      expect(route.wildcard?).to be false
    end
  end

  describe "#description" do
    it "returns 'Return Path' for return path routes" do
      route = build(:route, name: "__returnpath__")
      expect(route.description).to eq("Return Path")
    end

    it "returns name@domain for regular routes" do
      route = build(:route, name: "test", domain: domain)
      expect(route.description).to eq("test@#{domain.name}")
    end
  end

  describe "#forward_address" do
    it "returns token@route_domain" do
      route = create(:route, server: server, domain: domain, mode: "Bounce")
      expect(route.forward_address).to eq("#{route.token}@#{Postal::Config.dns.route_domain}")
    end
  end

  describe "#_endpoint=" do
    let(:route) { build(:route, server: server, domain: domain) }

    it "sets mode for non-endpoint values" do
      route._endpoint = "Bounce"
      expect(route.mode).to eq("Bounce")
      expect(route.endpoint).to be_nil
    end

    it "sets endpoint for endpoint values" do
      http_endpoint = create(:http_endpoint, server: server)
      route._endpoint = "HTTPEndpoint##{http_endpoint.uuid}"
      expect(route.mode).to eq("Endpoint")
      expect(route.endpoint).to eq(http_endpoint)
    end

    it "clears endpoint for blank value" do
      route._endpoint = ""
      expect(route.mode).to be_nil
      expect(route.endpoint).to be_nil
    end

    it "raises error for invalid endpoint class" do
      expect {
        route._endpoint = "InvalidClass#123"
      }.to raise_error(Postal::Error, /Invalid endpoint class name/)
    end
  end

  describe ".find_by_name_and_domain" do
    it "finds exact match" do
      route = create(:route, server: server, domain: domain, name: "test", mode: "Bounce")
      found = Route.find_by_name_and_domain("test", domain.name)
      expect(found).to eq(route)
    end

    it "falls back to wildcard route" do
      wildcard = create(:route, server: server, domain: domain, name: "*", mode: "Bounce")
      found = Route.find_by_name_and_domain("nonexistent", domain.name)
      expect(found).to eq(wildcard)
    end

    it "returns nil when no match" do
      found = Route.find_by_name_and_domain("test", "nonexistent.com")
      expect(found).to be_nil
    end
  end

  describe "token generation" do
    it "generates unique token on create" do
      route = create(:route, server: server, domain: domain, mode: "Bounce")
      expect(route.token).to be_present
      expect(route.token.length).to eq(8)
    end
  end
end
