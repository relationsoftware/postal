# frozen_string_literal: true

require "rails_helper"

RSpec.describe IPPool, type: :model do
  describe "associations" do
    it { should have_many(:ip_addresses).dependent(:restrict_with_exception) }
    it { should have_many(:servers).dependent(:restrict_with_exception) }
    it { should have_many(:organization_ip_pools).dependent(:destroy) }
    it { should have_many(:organizations).through(:organization_ip_pools) }
    it { should have_many(:ip_pool_rules).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "default values" do
    it "defaults 'default' to false" do
      pool = IPPool.new
      expect(pool.default).to be false
    end
  end

  describe ".default" do
    it "returns the default pool" do
      non_default = create(:ip_pool, default: false)
      default_pool = create(:ip_pool, default: true)

      expect(IPPool.default).to eq(default_pool)
    end

    it "returns first default pool when multiple exist" do
      first_default = create(:ip_pool, default: true)
      second_default = create(:ip_pool, default: true)

      expect(IPPool.default).to eq(first_default)
    end

    it "returns nil when no default pool exists" do
      create(:ip_pool, default: false)
      expect(IPPool.default).to be_nil
    end
  end

  describe "UUID" do
    it "generates UUID on create" do
      pool = create(:ip_pool)
      expect(pool.uuid).to be_present
      expect(pool.uuid).to match(/\A[a-f0-9-]{36}\z/)
    end
  end

  describe "dependent restrictions" do
    it "prevents deletion when IP addresses exist" do
      pool = create(:ip_pool)
      create(:ip_address, ip_pool: pool)

      expect { pool.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    it "prevents deletion when servers exist" do
      pool = create(:ip_pool)
      create(:server, ip_pool: pool)

      expect { pool.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    it "allows deletion when no dependencies exist" do
      pool = create(:ip_pool)
      expect { pool.destroy! }.to change(IPPool, :count).by(-1)
    end
  end
end
