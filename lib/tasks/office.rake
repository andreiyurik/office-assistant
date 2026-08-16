namespace :office do
  desc "Release room bookings nobody checked in to"
  task release: :environment do
    released = ReleaseAbandonedBookingsJob.perform_now

    puts "Released #{released} booking(s)"
  end
end
