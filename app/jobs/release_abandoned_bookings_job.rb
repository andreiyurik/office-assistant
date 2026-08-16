# Frees meeting rooms that were booked and then never used: the slot started
# more than ten minutes ago and nobody in the meeting checked in.
class ReleaseAbandonedBookingsJob < ApplicationJob
  queue_as :default

  def perform
    released = Booking.release_abandoned!

    Rails.logger.info("Released #{released} abandoned room booking(s)") if released.positive?
    released
  end
end
