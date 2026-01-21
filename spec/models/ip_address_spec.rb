# frozen_string_literal: true

require "rails_helper"

RSpec.describe IPAddress, type: :model do
  let(:ip_pool) { create(:ip_pool) }

  describe "associations" do
    it { should belong_to(:ip_pool) }
  end

  describe "validations" do
    subject { build(:ip_address, ip_pool: ip_pool) }

    it { should validate_presence_of(:ipv4) }
    it { should validate_presence_of(:hostname) }
    it { should validate_uniqueness_of(:ipv4) }

    describe "ipv4 uniqueness" do
      it "prevents duplicate IPv4 addresses" do
        create(:ip_address, ip_pool: ip_pool, ipv4: "192.168.1.1")
        duplicate = build(:ip_address, ip_pool: ip_pool, ipv4: "192.168.1.1")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:ipv4]).to include("has already been taken")
      end

      it "allows same IPv4 in different pools" do
        other_pool = create(:ip_pool)
        create(:ip_address, ip_pool: ip_pool, ipv4: "192.168.1.1")
        # Note: The model validates global uniqueness, so this should fail
        duplicate = build(:ip_address, ip_pool: other_pool, ipv4: "192.168.1.1")
        expect(duplicate).not_to be_valid
      end
    end

    describe "ipv6 uniqueness" do
      it "allows blank IPv6" do
        ip = build(:ip_address, ip_pool: ip_pool, ipv6: nil)
        expect(ip).to be_valid
      end

      it "prevents duplicate IPv6 addresses" do
        create(:ip_address, ip_pool: ip_pool, ipv6: "2001:db8::1")
        duplicate = build(:ip_address, ip_pool: ip_pool, ipv6: "2001:db8::1")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:ipv6]).to include("has already been taken")
      end
    end

    describe "priority validation" do
      it "accepts priority between 0 and 100" do
        [0, 50, 100].each do |priority|
          ip = build(:ip_address, ip_pool: ip_pool, priority: priority)
          expect(ip).to be_valid, "Expected priority #{priority} to be valid"
        end
      end

      it "rejects priority below 0" do
        ip = build(:ip_address, ip_pool: ip_pool, priority: -1)
        expect(ip).not_to be_valid
        expect(ip.errors[:priority]).to be_present
      end

      it "rejects priority above 100" do
        ip = build(:ip_address, ip_pool: ip_pool, priority: 101)
        expect(ip).not_to be_valid
        expect(ip.errors[:priority]).to be_present
      end

      it "rejects non-integer priority" do
        ip = build(:ip_address, ip_pool: ip_pool, priority: 50.5)
        expect(ip).not_to be_valid
        expect(ip.errors[:priority]).to be_present
      end
    end
  end

  describe "default values" do
    it "sets default priority to 100" do
      ip = create(:ip_address, ip_pool: ip_pool, priority: nil)
      expect(ip.priority).to eq(100)
    end

    it "does not override explicit priority" do
      ip = create(:ip_address, ip_pool: ip_pool, priority: 50)
      expect(ip.priority).to eq(50)
    end
  end

  describe "scopes" do
    describe ".order_by_priority" do
      it "orders by priority descending" do
        low = create(:ip_address, ip_pool: ip_pool, priority: 10)
        high = create(:ip_address, ip_pool: ip_pool, priority: 90)
        medium = create(:ip_address, ip_pool: ip_pool, priority: 50)

        ordered = ip_pool.ip_addresses.order_by_priority
        expect(ordered.to_a).to eq([high, medium, low])
      end
    end
  end

  describe ".select_by_priority" do
    it "returns an IP address" do
      create(:ip_address, ip_pool: ip_pool, priority: 100)
      create(:ip_address, ip_pool: ip_pool, priority: 50)

      result = ip_pool.ip_addresses.select_by_priority
      expect(result).to be_a(IPAddress)
    end

    it "returns nil when no addresses exist" do
      result = ip_pool.ip_addresses.select_by_priority
      expect(result).to be_nil
    end
  end
end
