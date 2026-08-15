class Resource < ApplicationRecord
  KINDS = %w[desk room].freeze

  belongs_to :zone
  has_many :bookings, dependent: :destroy

  validates :kind, inclusion: { in: KINDS }
  validates :name, presence: true

  scope :desks, -> { where(kind: "desk").order(:grid_row, :grid_col) }
  scope :rooms, -> { where(kind: "room").order(:name) }

  def desk?
    kind == "desk"
  end

  def room?
    kind == "room"
  end
end
