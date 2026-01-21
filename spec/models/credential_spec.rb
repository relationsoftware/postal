# frozen_string_literal: true

require "rails_helper"

RSpec.describe Credential, type: :model do
  let(:server) { create(:server) }

  describe "validations" do
    it { should belong_to(:server) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:key) }
    it { should validate_inclusion_of(:type).in_array(Credential::TYPES) }

    context "key uniqueness" do
      context "for SMTP credentials" do
        let!(:existing) { create(:credential, server: server, type: "SMTP") }

        it "validates global uniqueness" do
          other_server = create(:server)
          credential = build(:credential, server: other_server, type: "SMTP", key: existing.key)
          expect(credential).not_to be_valid
          expect(credential.errors[:key]).to include("has already been taken")
        end
      end

      context "for SMTP-IP credentials" do
        let!(:existing) { create(:credential, server: server, type: "SMTP-IP", key: "192.168.1.1") }

        it "validates uniqueness within server scope" do
          credential = build(:credential, server: server, type: "SMTP-IP", key: "192.168.1.1")
          expect(credential).not_to be_valid
        end

        it "allows same IP on different servers" do
          other_server = create(:server)
          credential = build(:credential, server: other_server, type: "SMTP-IP", key: "192.168.1.1")
          expect(credential).to be_valid
        end
      end
    end

    context "key validation for SMTP-IP" do
      it "requires valid IPv4 address" do
        credential = build(:credential, server: server, type: "SMTP-IP", key: "invalid")
        expect(credential).not_to be_valid
        expect(credential.errors[:key]).to include("must be a valid IPv4 or IPv6 address")
      end

      it "accepts valid IPv4 address" do
        credential = build(:credential, server: server, type: "SMTP-IP", key: "10.0.0.1")
        expect(credential).to be_valid
      end

      it "accepts valid IPv6 address" do
        credential = build(:credential, server: server, type: "SMTP-IP", key: "2001:db8::1")
        expect(credential).to be_valid
      end
    end

    context "key cannot be changed" do
      it "prevents key change for SMTP credentials" do
        credential = create(:credential, server: server, type: "SMTP")
        original_key = credential.key
        credential.key = "newkey123"
        expect(credential).not_to be_valid
        expect(credential.errors[:key]).to include("cannot be changed")
      end

      it "allows key change for SMTP-IP credentials" do
        credential = create(:credential, server: server, type: "SMTP-IP", key: "192.168.1.1")
        credential.key = "192.168.1.2"
        expect(credential).to be_valid
      end
    end
  end

  describe "key generation" do
    it "auto-generates key for SMTP credentials" do
      credential = build(:credential, server: server, type: "SMTP", key: nil)
      credential.valid?
      expect(credential.key).to be_present
      expect(credential.key.length).to eq(24)
    end

    it "auto-generates key for API credentials" do
      credential = build(:credential, server: server, type: "API", key: nil)
      credential.valid?
      expect(credential.key).to be_present
    end

    it "does not auto-generate key for SMTP-IP credentials" do
      credential = build(:credential, server: server, type: "SMTP-IP", key: nil)
      credential.valid?
      expect(credential.key).to be_nil
    end

    it "does not regenerate key on update" do
      credential = create(:credential, server: server, type: "SMTP")
      original_key = credential.key
      credential.name = "Updated Name"
      credential.save!
      expect(credential.key).to eq(original_key)
    end
  end

  describe "#smtp_ip?" do
    it "returns true for SMTP-IP type" do
      credential = build(:credential, type: "SMTP-IP", key: "192.168.1.1")
      expect(credential.smtp_ip?).to be true
    end

    it "returns false for SMTP type" do
      credential = build(:credential, type: "SMTP")
      expect(credential.smtp_ip?).to be false
    end

    it "returns false for API type" do
      credential = build(:credential, type: "API")
      expect(credential.smtp_ip?).to be false
    end
  end

  describe "#use" do
    it "updates last_used_at timestamp" do
      credential = create(:credential, server: server)
      expect(credential.last_used_at).to be_nil

      Timecop.freeze(Time.now) do
        credential.use
        expect(credential.reload.last_used_at).to be_within(1.second).of(Time.now)
      end
    end
  end

  describe "#usage_type" do
    let(:credential) { create(:credential, server: server) }

    it "returns 'Unused' when never used" do
      expect(credential.usage_type).to eq("Unused")
    end

    it "returns 'Active' when used recently" do
      credential.update_column(:last_used_at, 1.day.ago)
      expect(credential.usage_type).to eq("Active")
    end

    it "returns 'Quiet' when used 2 months ago" do
      credential.update_column(:last_used_at, 2.months.ago)
      expect(credential.usage_type).to eq("Quiet")
    end

    it "returns 'Dormant' when used 7 months ago" do
      credential.update_column(:last_used_at, 7.months.ago)
      expect(credential.usage_type).to eq("Dormant")
    end

    it "returns 'Inactive' when used over a year ago" do
      credential.update_column(:last_used_at, 13.months.ago)
      expect(credential.usage_type).to eq("Inactive")
    end
  end

  describe "#to_smtp_plain" do
    it "returns base64 encoded SMTP PLAIN auth string" do
      credential = create(:credential, server: server, type: "SMTP")
      result = credential.to_smtp_plain
      decoded = Base64.decode64(result)
      expect(decoded).to eq("\0XX\0#{credential.key}")
    end
  end

  describe "#ipaddr" do
    it "returns IPAddr for SMTP-IP credentials" do
      credential = build(:credential, type: "SMTP-IP", key: "192.168.1.1")
      expect(credential.ipaddr).to be_a(IPAddr)
      expect(credential.ipaddr.to_s).to eq("192.168.1.1")
    end

    it "returns nil for non-SMTP-IP credentials" do
      credential = build(:credential, type: "SMTP")
      expect(credential.ipaddr).to be_nil
    end

    it "returns nil for invalid IP" do
      credential = build(:credential, type: "SMTP-IP")
      credential.instance_variable_set(:@key, "invalid")
      allow(credential).to receive(:key).and_return("invalid")
      expect(credential.ipaddr).to be_nil
    end
  end

  describe "#to_param" do
    it "returns uuid" do
      credential = create(:credential, server: server)
      expect(credential.to_param).to eq(credential.uuid)
    end
  end

  describe "TYPES constant" do
    it "includes all valid types" do
      expect(Credential::TYPES).to eq(%w[SMTP API SMTP-IP])
    end
  end
end
