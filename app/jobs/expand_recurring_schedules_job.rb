# Keeps every recurring schedule booked two weeks ahead. Runs once a day: the
# horizon rolls forward one day at a time.
class ExpandRecurringSchedulesJob < ApplicationJob
  queue_as :default

  def perform
    created = RecurringSchedule.find_each.sum { |schedule| schedule.expand!.size }

    Rails.logger.info("Recurring schedules created #{created} desk booking(s)") if created.positive?
    created
  end
end
