class RecurringSchedule < ApplicationRecord
  # How far ahead the background job books desks.
  HORIZON = 2.weeks

  # Monday to Friday, using the same numbering as Date#wday.
  WORKDAYS = (1..5).to_a.freeze

  belongs_to :user
  belongs_to :resource

  validates :valid_from, presence: true
  validate :weekdays_are_workdays
  validate :resource_is_a_desk

  # The dates this schedule covers inside the horizon.
  def dates(from: Date.current, horizon: HORIZON)
    first = [ from, valid_from ].compact.max
    last = [ from + horizon, valid_to ].compact.min
    return [] if last < first

    (first..last).select { |date| weekdays.include?(date.wday) }
  end

  # Books the desk on every covered date. A date where the desk is already
  # taken, or where the person already has another desk, simply fails
  # validation and is skipped — the schedule never overrides a real booking.
  def expand!(from: Date.current, horizon: HORIZON)
    dates(from: from, horizon: horizon).filter_map do |date|
      booking = Booking.new(user: user, resource: resource, starts_at: date.beginning_of_day)
      booking if booking.save
    end
  end

  # Called when the person edits the schedule: days they dropped should stop
  # holding a desk, and the days they kept are booked ahead.
  def apply!(from: Date.current)
    future_bookings(from)
      .reject { |booking| weekdays.include?(booking.starts_at.to_date.wday) }
      .each { |booking| booking.update!(state: "cancelled") }

    expand!(from: from)
  end

  # Called when the person turns the schedule off entirely.
  def cancel_future_bookings!(from: Date.current)
    future_bookings(from).each { |booking| booking.update!(state: "cancelled") }
  end

  private
    # Everything this person holds at this desk from tomorrow on. Today is left
    # alone: they are already in the office.
    def future_bookings(from)
      user.bookings.active
        .where(resource_id: resource_id)
        .where(starts_at: (from + 1.day).beginning_of_day..)
        .to_a
    end

    def weekdays_are_workdays
      if weekdays.blank?
        errors.add(:base, "Выберите хотя бы один день недели.")
      elsif weekdays.any? { |weekday| !WORKDAYS.include?(weekday) }
        errors.add(:base, "В расписании можно выбрать только будние дни.")
      end
    end

    def resource_is_a_desk
      return if resource.blank?

      if resource.room?
        errors.add(:base, "Повторяющееся расписание работает только для рабочих мест.")
      end
    end
end
