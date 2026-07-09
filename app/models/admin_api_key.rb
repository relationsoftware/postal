# frozen_string_literal: true

# == Schema Information
#
# Table name: admin_api_keys
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  key          :string(255)
#  user_id      :integer
#  last_used_at :datetime
#  uuid         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_admin_api_keys_on_user_id  (user_id)
#  index_admin_api_keys_on_uuid     (uuid)
#

class AdminAPIKey < ApplicationRecord

  include HasUUID

  belongs_to :user

  validates :name, presence: true
  validates :key, presence: true, uniqueness: { case_sensitive: false }

  before_validation :generate_key, on: :create

  def use
    update_column(:last_used_at, Time.now)
  end

  private

  def generate_key
    self.key ||= SecureRandom.alphanumeric(32)
  end

end
