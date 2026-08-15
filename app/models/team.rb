class Team < ApplicationRecord
  belongs_to :zone
  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true
end
