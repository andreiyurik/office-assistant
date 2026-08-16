# Demo data for one hybrid office: 4 zones, 6 teams, 40 desks, 6 rooms,
# 60 people, and bookings for today and the next four days.
#
# These are demo seeds, not reference data, so the file rebuilds everything on
# every run (`bin/rails db:seed`, a few seconds). The random number generator
# has a fixed seed, so the same office comes out every time; only the bookings
# that depend on the clock move.
#
# What comes out and where to look for it:
#
#   1. Office layout      — zones, teams, a 4x10 desk grid, six rooms
#   2. People             — 60 accounts, password "password" for everyone
#   3. Recurring schedules — 8 regulars who hold their desk on fixed weekdays
#   4. Desk bookings      — today and four days ahead, teams seated together
#   5. Room bookings      — three meetings per room per day, past ones attended
#   6. The demo account   — anna.ivanova@office.ru, prepared for a live booking
#   7. Three room bookings that make auto-release visible on screen
#
# Re-run the seeds shortly before a demo: section 7 places bookings relative to
# the current time. The summary printed at the end says what to show and where.

rng = Random.new(20260815)

# Knobs. Everything else in the file follows from these.
days_ahead = 5                              # today plus four days, matches DayStrip
attendance_per_day = [ 22, 21, 19, 17, 14 ] # desks taken on each of those days, out of 40
keep_free_per_zone = 2                      # so there is always a desk to book live in every zone
regulars = 8                                # people with a recurring weekday schedule
meetings_per_room_per_day = 3

Session.delete_all
Booking.delete_all
RecurringSchedule.delete_all
User.delete_all
Resource.delete_all
Team.delete_all
Zone.delete_all

# --- 1. Office layout ---------------------------------------------------------

north = Zone.create!(name: "Север", floor: 3)
south = Zone.create!(name: "Юг", floor: 3)
west = Zone.create!(name: "Запад", floor: 3)
east = Zone.create!(name: "Восток", floor: 3)

teams = [
  [ "Платформа", north ],
  [ "Мобильная разработка", north ],
  [ "Продажи", south ],
  [ "Маркетинг", south ],
  [ "Финансы", west ],
  [ "Поддержка", east ]
].map { |name, zone| Team.create!(name: name, zone: zone) }

# The floor is a 4 by 10 grid. Each zone owns one 2 by 5 block of it.
desk_number = 0
(1..4).each do |row|
  (1..10).each do |col|
    zone = if row <= 2
      col <= 5 ? north : south
    else
      col <= 5 ? west : east
    end

    desk_number += 1
    Resource.create!(
      kind: "desk",
      name: desk_number.to_s,
      zone: zone,
      grid_row: row,
      grid_col: col
    )
  end
end

[
  [ "Берлин", 8, north ],
  [ "Осло", 4, north ],
  [ "Токио", 6, south ],
  [ "Лима", 2, west ],
  [ "Порту", 10, east ],
  [ "Ханой", 4, east ]
].each do |name, capacity, zone|
  Resource.create!(kind: "room", name: name, capacity: capacity, zone: zone)
end

desks = Resource.desks.to_a
rooms = Resource.rooms.to_a

# --- 2. People ----------------------------------------------------------------
# Ten first names x six surnames. Emails are latin: anna.ivanova@office.ru,
# dmitry.petrov@office.ru and so on; women get an "a" at the end of the surname.

first_names = [
  [ "Анна", "anna", :f ],
  [ "Мария", "maria", :f ],
  [ "Ольга", "olga", :f ],
  [ "Екатерина", "ekaterina", :f ],
  [ "Ирина", "irina", :f ],
  [ "Дмитрий", "dmitry", :m ],
  [ "Сергей", "sergey", :m ],
  [ "Алексей", "alexey", :m ],
  [ "Павел", "pavel", :m ],
  [ "Никита", "nikita", :m ]
]

surnames = [
  [ "Иванов", "ivanov" ],
  [ "Петров", "petrov" ],
  [ "Смирнов", "smirnov" ],
  [ "Кузнецов", "kuznetsov" ],
  [ "Соколов", "sokolov" ],
  [ "Морозов", "morozov" ]
]

users = []

first_names.each_with_index do |(first_ru, first_lat, gender), first_index|
  surnames.each_with_index do |(surname_ru, surname_lat), surname_index|
    female = gender == :f
    surname = female ? "#{surname_ru}а" : surname_ru
    team = teams[(first_index + surname_index) % teams.size]

    users << User.create!(
      name: "#{first_ru} #{surname}",
      email_address: "#{first_lat}.#{surname_lat}#{'a' if female}@office.ru",
      password: "password",
      team: team
    )
  end
end

# Every third person has a favourite desk in their team's zone.
desks_by_zone = desks.group_by(&:zone_id)
claimed_desk_ids = []

users.each_with_index do |user, index|
  next unless (index % 3).zero?

  desk = desks_by_zone[user.team.zone_id].find { |candidate| !claimed_desk_ids.include?(candidate.id) }
  next if desk.nil?

  claimed_desk_ids << desk.id
  user.update!(default_desk: desk)
end

# --- 3. Recurring schedules ---------------------------------------------------
# Expanded first, so a regular visitor keeps their desk and the random bookings
# below fill in around them. Half come Mon/Wed/Fri, half Tue/Thu.

users.select(&:default_desk).first(regulars).each_with_index do |user, index|
  schedule = RecurringSchedule.create!(
    user: user,
    resource: user.default_desk,
    weekdays: index.even? ? [ 1, 3, 5 ] : [ 2, 4 ],
    valid_from: Date.current
  )

  schedule.expand!
end

# --- 4. Desk bookings for today and the days ahead ----------------------------
# Attendance falls off towards the end of the week on purpose: the "who is in
# the office" screen should look different from day to day.

days = (0...days_ahead).map { |offset| Date.current + offset }

days.each_with_index do |date, index|
  taken_desk_ids = Booking.active.on_date(date).pluck(:resource_id)
  busy_user_ids = Booking.active.on_date(date).pluck(:user_id)

  users.shuffle(random: rng).each do |user|
    break if taken_desk_ids.size >= attendance_per_day[index]
    next if busy_user_ids.include?(user.id)

    free_by_zone = desks
      .reject { |desk| taken_desk_ids.include?(desk.id) }
      .group_by(&:zone_id)
      .select { |_zone_id, free| free.size > keep_free_per_zone }

    # Own zone fills up in order, so a team sits together. Whoever does not
    # fit lands anywhere free — that is the pain this product is about.
    desk = free_by_zone[user.team.zone_id]&.first || free_by_zone.values.flatten.sample(random: rng)
    break if desk.nil?

    Booking.create!(user: user, resource: desk, starts_at: date.beginning_of_day)
    taken_desk_ids << desk.id
    busy_user_ids << user.id
  end
end

# --- 5. Room bookings ---------------------------------------------------------
# Random half-hour and hour-long meetings. A meeting that collides with one
# already placed is simply skipped, so a room may end up with fewer than
# `meetings_per_room_per_day`.

days.each do |date|
  slot_starts = Booking.slot_starts_for(date)

  rooms.each do |room|
    meetings_per_room_per_day.times do
      first_slot = rng.rand(slot_starts.size - 1)
      length = rng.rand(1..2)
      starts = slot_starts[first_slot, length]
      organizer = users.sample(random: rng)
      group_id = SecureRandom.uuid

      # Meetings whose slot has already passed were attended: their organiser
      # checked in. Without this every past slot of today would look abandoned
      # and the release job would free two dozen of them at once.
      attended = starts.first < Time.current

      meeting = starts.map do |slot_start|
        Booking.new(
          user: organizer,
          resource: room,
          starts_at: slot_start,
          group_id: group_id,
          state: attended ? "checked_in" : "booked",
          checked_in_at: attended ? slot_start : nil
        )
      end

      next unless meeting.all?(&:valid?)

      meeting.each(&:save!)
    end
  end
end

# --- 6. The account the demo is shown from ------------------------------------
# The first person (Anna Ivanova, team "Платформа", zone "Север") opens the app
# to a useful picture: at least four teammates already in the office, her
# favourite desk still free, and no desk of her own yet — so booking one is
# something that can be done live on screen.

demo_user = users.first
desk_ids = desks.map(&:id)

Booking.active.on_date(Date.current).where(user: demo_user, resource_id: desk_ids).delete_all
Booking.active.on_date(Date.current).where(resource_id: demo_user.default_desk_id).delete_all

teammates = users.select { |user| user.team_id == demo_user.team_id && user != demo_user }
present_ids = Booking.active.on_date(Date.current)
  .where(user: teammates, resource_id: desk_ids)
  .pluck(:user_id)
wanted = [ 4 - present_ids.size, 0 ].max

teammates.reject { |user| present_ids.include?(user.id) }.first(wanted).each do |teammate|
  taken_ids = Booking.active.on_date(Date.current).pluck(:resource_id)
  desk = desks_by_zone[demo_user.team.zone_id].find do |candidate|
    !taken_ids.include?(candidate.id) && candidate.id != demo_user.default_desk_id
  end
  next if desk.nil?

  Booking.create!(user: teammate, resource: desk, starts_at: Date.current.beginning_of_day)
end

# --- 7. Three room bookings that make auto-release visible --------------------
# All three sit in slots that have already started today, so nothing has to be
# waited for. Before the office opens (or after it closes) they fall back to the
# first slot of the day and the "abandoned" one is not yet due for release.

today_slots = Booking.slot_starts_for(Date.current)
started_slots = today_slots.select { |slot| slot <= Time.current - Booking::RELEASE_AFTER }

abandoned_slot = started_slots.last || today_slots.first
released_slot = started_slots.first || today_slots.first
checked_in_slot = started_slots[-2] || today_slots.first

# Booked, the slot started more than ten minutes ago, nobody checked in: this is
# the one `bin/rails office:release` frees during the demo.
Booking.active.where(starts_at: abandoned_slot, resource: rooms).delete_all
Booking.create!(user: users[0], resource: rooms[0], starts_at: abandoned_slot)

# Checked in, so the same job must leave it alone.
Booking.active.where(starts_at: checked_in_slot, resource: rooms).delete_all
Booking.create!(
  user: users[1],
  resource: rooms[1],
  starts_at: checked_in_slot,
  state: "checked_in",
  checked_in_at: checked_in_slot
)

# Already released earlier today, so the marker is visible without running
# anything.
Booking.active.where(starts_at: released_slot, resource: rooms).delete_all
Booking.create!(user: users[2], resource: rooms[2], starts_at: released_slot, state: "released")

# --- Summary: what to show ----------------------------------------------------

teammates_present = Booking.active.on_date(Date.current).where(user: teammates, resource_id: desk_ids).count

puts "Zones: #{Zone.count}, teams: #{Team.count}, desks: #{Resource.desks.count}, rooms: #{Resource.rooms.count}"
puts "People: #{User.count}, all with password 'password'"
puts "Bookings: #{Booking.count} (#{Booking.active.desks.on_date(Date.current).count} desks taken today)"
puts "Recurring schedules: #{RecurringSchedule.count}"
puts
puts "Demo account: #{demo_user.email_address} (#{demo_user.name}, #{demo_user.team.name})"
puts "  favourite desk #{demo_user.default_desk.name} is free, #{teammates_present} teammates are in today"
puts "Rooms today, for the auto-release story:"
puts "  #{rooms[0].name} #{abandoned_slot.strftime('%H:%M')} — booked, no check-in: `bin/rails office:release` frees it"
puts "  #{rooms[1].name} #{checked_in_slot.strftime('%H:%M')} — checked in: the same job leaves it alone"
puts "  #{rooms[2].name} #{released_slot.strftime('%H:%M')} — already released, shown as 'освободилось'"
