# Demo data for one hybrid office: 4 zones, 6 teams, 40 desks, 6 rooms,
# 60 people, and bookings for today and the next four days.
#
# These are demo seeds, not reference data, so the file rebuilds everything on
# every run. The random number generator has a fixed seed, so the same office
# comes out every time.

rng = Random.new(20260815)

Session.delete_all
Booking.delete_all
RecurringSchedule.delete_all
User.delete_all
Resource.delete_all
Team.delete_all
Zone.delete_all

# --- Office layout ------------------------------------------------------------

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

# --- People -------------------------------------------------------------------

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

# --- Recurring schedules ------------------------------------------------------
# Expanded first, so a regular visitor keeps their desk and the random bookings
# below fill in around them.

users.select(&:default_desk).first(8).each_with_index do |user, index|
  schedule = RecurringSchedule.create!(
    user: user,
    resource: user.default_desk,
    weekdays: index.even? ? [ 1, 3, 5 ] : [ 2, 4 ],
    valid_from: Date.current
  )

  schedule.expand!
end

# --- Desk bookings for today and the next four days ---------------------------

days = (0..4).map { |offset| Date.current + offset }
attendance_per_day = [ 22, 21, 19, 17, 14 ]

# Every zone keeps this many desks free, so there is always something to book
# on the map during a demo.
keep_free_per_zone = 2

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

# --- Room bookings ------------------------------------------------------------

days.each do |date|
  slot_starts = Booking.slot_starts_for(date)

  rooms.each do |room|
    3.times do
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

# --- The account the demo is shown from ---------------------------------------
# The first person opens the app to a useful picture: teammates already in the
# office, her favourite desk still free, and no desk of her own yet — so booking
# one is something that can be done live on screen.

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

# --- Three bookings that make the demo visible --------------------------------
# Re-run the seeds shortly before a demo: the abandoned booking is placed
# relative to the current time.

today_slots = Booking.slot_starts_for(Date.current)
started_slots = today_slots.select { |slot| slot <= Time.current - Booking::RELEASE_AFTER }

abandoned_slot = started_slots.last || today_slots.first
released_slot = started_slots.first || today_slots.first
checked_in_slot = started_slots[-2] || today_slots.first

# Booked, the slot has already started, nobody checked in: the auto-release job
# will free this one.
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

puts "Zones: #{Zone.count}, teams: #{Team.count}, desks: #{Resource.desks.count}, rooms: #{Resource.rooms.count}"
puts "People: #{User.count}, all with password 'password'"
puts "Bookings: #{Booking.count} (#{Booking.active.desks.on_date(Date.current).count} desks taken today)"
puts "Recurring schedules: #{RecurringSchedule.count}"
puts "Abandoned room booking waiting for the job: #{rooms[0].name} at #{abandoned_slot.strftime('%d.%m %H:%M')}"
