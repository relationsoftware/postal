# frozen_string_literal: true

require "rails_helper"

RSpec.describe Webhook, type: :model do
  let(:server) { create(:server) }

  describe "associations" do
    it { should belong_to(:server) }
    it { should have_many(:webhook_events).dependent(:destroy) }
    it { should have_many(:webhook_requests) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:url) }

    describe "url format" do
      it "accepts valid HTTP URLs" do
        webhook = build(:webhook, server: server, url: "http://example.com/webhook")
        expect(webhook).to be_valid
      end

      it "accepts valid HTTPS URLs" do
        webhook = build(:webhook, server: server, url: "https://example.com/webhook")
        expect(webhook).to be_valid
      end

      it "accepts URLs with query parameters" do
        webhook = build(:webhook, server: server, url: "https://example.com/webhook?key=value&other=123")
        expect(webhook).to be_valid
      end

      it "accepts URLs with ports" do
        webhook = build(:webhook, server: server, url: "https://example.com:8080/webhook")
        expect(webhook).to be_valid
      end

      it "accepts URLs with authentication" do
        webhook = build(:webhook, server: server, url: "https://user:pass@example.com/webhook")
        expect(webhook).to be_valid
      end

      it "rejects invalid URLs" do
        webhook = build(:webhook, server: server, url: "not-a-url")
        expect(webhook).not_to be_valid
        expect(webhook.errors[:url]).to be_present
      end

      it "rejects FTP URLs" do
        webhook = build(:webhook, server: server, url: "ftp://example.com/file")
        expect(webhook).not_to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".enabled" do
      it "returns only enabled webhooks" do
        enabled = create(:webhook, server: server, enabled: true)
        disabled = create(:webhook, server: server, enabled: false)

        expect(Webhook.enabled).to include(enabled)
        expect(Webhook.enabled).not_to include(disabled)
      end
    end
  end

  describe "default values" do
    it "defaults enabled to true" do
      webhook = Webhook.new
      expect(webhook.enabled).to be true
    end

    it "defaults all_events to false" do
      webhook = Webhook.new
      expect(webhook.all_events).to be false
    end

    it "defaults sign to true" do
      webhook = Webhook.new
      expect(webhook.sign).to be true
    end
  end

  describe "#events" do
    it "returns array of event names" do
      webhook = create(:webhook, server: server)
      webhook.webhook_events.create!(event: "MessageSent")
      webhook.webhook_events.create!(event: "MessageDelivered")

      expect(webhook.events).to contain_exactly("MessageSent", "MessageDelivered")
    end

    it "returns empty array when no events" do
      webhook = create(:webhook, server: server)
      expect(webhook.events).to eq([])
    end
  end

  describe "#events=" do
    it "sets events to be saved" do
      webhook = create(:webhook, server: server)
      webhook.events = ["MessageSent", "MessageBounced"]
      webhook.save!

      expect(webhook.reload.events).to contain_exactly("MessageSent", "MessageBounced")
    end

    it "removes events not in new list" do
      webhook = create(:webhook, server: server)
      webhook.webhook_events.create!(event: "MessageSent")
      webhook.webhook_events.create!(event: "MessageDelivered")

      webhook.events = ["MessageSent"]
      webhook.save!

      expect(webhook.reload.events).to eq(["MessageSent"])
    end

    it "ignores blank values" do
      webhook = create(:webhook, server: server)
      webhook.events = ["MessageSent", "", nil, "MessageBounced"]
      webhook.save!

      expect(webhook.reload.events).to contain_exactly("MessageSent", "MessageBounced")
    end
  end

  describe "all_events behavior" do
    it "destroys specific events when all_events is enabled" do
      webhook = create(:webhook, server: server, all_events: false)
      webhook.webhook_events.create!(event: "MessageSent")
      webhook.webhook_events.create!(event: "MessageDelivered")

      webhook.update!(all_events: true)

      expect(webhook.webhook_events.count).to eq(0)
    end
  end

  describe "UUID" do
    it "generates UUID on create" do
      webhook = create(:webhook, server: server)
      expect(webhook.uuid).to be_present
      expect(webhook.uuid).to match(/\A[a-f0-9-]{36}\z/)
    end
  end
end
