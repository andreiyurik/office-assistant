class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_one :recurring_schedule, dependent: :destroy

  belongs_to :team
  belongs_to :default_desk, class_name: "Resource", optional: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
end
