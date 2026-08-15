class Zone < ApplicationRecord
  has_many :teams, dependent: :restrict_with_error
  has_many :resources, dependent: :restrict_with_error

  validates :name, presence: true
  validates :floor, presence: true
end
