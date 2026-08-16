class Booking < ApplicationRecord
  # A room is booked in fixed half-hour slots: one row is one slot.
  SLOT_MINUTES = 30
  SLOT = SLOT_MINUTES.minutes
  OPEN_HOUR = 9
  CLOSE_HOUR = 19

  # A room booking nobody checked in to is released this long after the slot
  # started. Ten minutes is the same threshold Robin uses by default.
  RELEASE_AFTER = 10.minutes

  # Confirming ahead of the meeting is allowed, the way Robin allows it.
  CHECK_IN_OPENS_BEFORE = 10.minutes

  ACTIVE_STATES = %w[booked checked_in].freeze
  STATES = (ACTIVE_STATES + %w[released cancelled]).freeze

  belongs_to :user
  belongs_to :resource

  scope :active, -> { where(state: ACTIVE_STATES) }
  scope :on_date, ->(date) { where(starts_at: date.all_day) }
  scope :desks, -> { joins(:resource).where(resources: { kind: "desk" }) }
  scope :rooms, -> { joins(:resource).where(resources: { kind: "room" }) }

  before_validation :normalize_period
  before_validation :assign_group_id

  validates :state, inclusion: { in: STATES }
  validates :starts_at, presence: true
  validate :room_slot_fits_the_grid
  validate :resource_is_free
  validate :user_is_free

  # The twenty slot start times of one office day, used by the room grid.
  def self.slot_starts_for(date)
    first = date.beginning_of_day.change(hour: OPEN_HOUR)
    count = (CLOSE_HOUR - OPEN_HOUR) * 60 / SLOT_MINUTES

    Array.new(count) { |index| first + (index * SLOT) }
  end

  # Releases room bookings whose slot started more than RELEASE_AFTER ago and
  # that nobody checked in to. A booking belongs to a group — a meeting longer
  # than one slot is several rows — and one check-in covers the whole group,
  # so an hour-long meeting is not cut in half while people sit in the room.
  def self.release_abandoned!(now: Time.current)
    checked_in_groups = where(state: "checked_in").select(:group_id)

    abandoned = active.rooms
      .where(state: "booked")
      .where(starts_at: ..(now - RELEASE_AFTER))
      .where.not(group_id: checked_in_groups)

    where(id: abandoned.pluck(:id)).update_all(state: "released", updated_at: now)
  end

  # A meeting is one row per slot, tied together by a group id: booking an hour
  # writes two rows, and everything that follows treats them as one meeting.
  def self.book_meeting!(user:, room:, starts_at:, slots: 1)
    group_id = SecureRandom.uuid

    transaction do
      Array.new(slots) do |index|
        create!(
          user: user,
          resource: room,
          starts_at: starts_at + (index * SLOT),
          group_id: group_id
        )
      end
    end
  end

  def check_in_open?(now = Time.current)
    now >= starts_at - CHECK_IN_OPENS_BEFORE && now < ends_at
  end

  # One check-in covers the whole meeting.
  def check_in!(now: Time.current)
    self.class.where(group_id: group_id, state: "booked")
      .update_all(state: "checked_in", checked_in_at: now, updated_at: now)
  end

  def cancel_meeting!(now: Time.current)
    self.class.active.where(group_id: group_id)
      .update_all(state: "cancelled", updated_at: now)
  end

  def active?
    ACTIVE_STATES.include?(state)
  end

  def checked_in?
    state == "checked_in"
  end

  def released?
    state == "released"
  end

  private
    # A desk is booked for the whole day, a room for one half-hour slot.
    def normalize_period
      return if resource.blank? || starts_at.blank?

      if resource.desk?
        self.starts_at = starts_at.beginning_of_day
        self.ends_at = starts_at + 1.day
      else
        self.ends_at = starts_at + SLOT
      end
    end

    def assign_group_id
      self.group_id = SecureRandom.uuid if group_id.blank?
    end

    def room_slot_fits_the_grid
      return if resource.blank? || resource.desk? || starts_at.blank?

      unless starts_at.min % SLOT_MINUTES == 0 && starts_at.sec.zero?
        errors.add(:base, "Переговорные бронируются получасовыми слотами: 9:00, 9:30 и так далее.")
      end

      unless starts_at.hour.between?(OPEN_HOUR, CLOSE_HOUR - 1)
        errors.add(:base, "Переговорные доступны с #{OPEN_HOUR}:00 до #{CLOSE_HOUR}:00. Выберите слот внутри рабочего дня.")
      end
    end

    # Mirrors index_bookings_on_active_resource_slot. The index is what
    # actually prevents the double booking; this exists to show the person a
    # readable message instead of a database error.
    def resource_is_free
      return if resource.blank? || starts_at.blank? || !active?

      taken = Booking.active
        .where(resource_id: resource_id, starts_at: starts_at)
        .where.not(id: id)
        .exists?
      return unless taken

      if resource.desk?
        errors.add(:base, "Это место уже заняли на выбранный день. Выберите другое — свободные подсвечены на карте.")
      else
        errors.add(:base, "Этот слот уже заняли. Выберите другое время или другую переговорную.")
      end
    end

    # Mirrors index_bookings_on_active_user_slot.
    def user_is_free
      return if user_id.blank? || starts_at.blank? || !active?

      busy = Booking.active
        .where(user_id: user_id, starts_at: starts_at)
        .where.not(id: id)
        .exists?
      return unless busy

      if resource&.desk?
        errors.add(:base, "У вас уже забронировано место на этот день. Сначала отмените текущую бронь.")
      else
        errors.add(:base, "У вас уже есть бронь на это время. Сначала отмените её.")
      end
    end
end
