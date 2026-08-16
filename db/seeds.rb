# A demo office you can log in to.
#
#   bin/rails db:seed     # rebuilds everything, takes a few seconds
#
# The file is in two halves. The first half is data: who can log in, the
# numbers worth changing before a demo, the floor plan, teams, rooms and names.
# The second half is the code that turns that data into rows. Read the first
# half; only open the second if something needs to change in how it is built.
#
# Everything is rebuilt on every run. Random choices use a fixed seed, so the
# same office comes out each time. The only things that move are the bookings
# tied to the clock — they are marked "(clock)" below — so re-run the seeds
# shortly before a demo. The summary printed at the end says what to show.

# =============================================================================
# DATA
# =============================================================================

# --- Accounts -----------------------------------------------------------------
# Password for everyone: "password". Emails are name.surname@office.ru in latin
# letters (dmitry.petrov@office.ru); a woman's surname ends in "a".
#
# The accounts the demo is built around:
#
#   anna.ivanova@office.ru      main account — team Платформа, zone Север.
#                               Favourite desk is free, four teammates are in,
#                               schedule Mon/Wed/Fri, and a meeting in Берлин
#                               she never checked in to (clock) — the one the
#                               release job frees on screen.
#   anna.petrova@office.ru      checked in to her meeting in Лима (clock) —
#                               the release job leaves it alone.
#   anna.smirnova@office.ru     her morning meeting in Осло was already released
#                               (clock) — the slot says "освободилось".
#   anna.kuznetsova@office.ru   another team and zone (Маркетинг, Юг),
#                               favourite desk, schedule Tue/Thu.
#
# The teammates of the main account who are in the office today (for the
# "sit next to a colleague" flow) depend on the weekday; the summary lists them.

MAIN_ACCOUNT = "anna.ivanova@office.ru"
CHECKED_IN_ACCOUNT = "anna.petrova@office.ru"
RELEASED_ACCOUNT = "anna.smirnova@office.ru"
PASSWORD = "password"

# --- Knobs --------------------------------------------------------------------

DAYS_AHEAD = 5                              # today plus four days: what DayStrip shows
ATTENDANCE_PER_DAY = [ 22, 21, 19, 17, 14 ] # desks taken on each of those days, out of 40
DESKS_KEPT_FREE_PER_ZONE = 2                # so a desk can be booked live in any zone
REGULARS = 8                                # people with a recurring weekday schedule
MEETINGS_PER_ROOM_PER_DAY = 3
TEAMMATES_IN_TODAY = 4                      # at least this many of the main account's team
RANDOM_SEED = 20260815

# --- The office ---------------------------------------------------------------

# Zone letter => name. All on the third floor.
ZONES = {
  "N" => "Север",
  "S" => "Юг",
  "W" => "Запад",
  "E" => "Восток"
}
FLOOR = 3

# The floor plan as it appears on the desk map: 4 rows by 10 columns, one
# letter per desk saying which zone it is in. Desks are numbered 1..40 left to
# right, top to bottom.
FLOOR_PLAN = [
  "NNNNNSSSSS",
  "NNNNNSSSSS",
  "WWWWWEEEEE",
  "WWWWWEEEEE"
]

# Team name => home zone letter. Two teams per zone in the north and south.
TEAMS = {
  "Платформа" => "N",
  "Мобильная разработка" => "N",
  "Продажи" => "S",
  "Маркетинг" => "S",
  "Финансы" => "W",
  "Поддержка" => "E"
}

# Meeting rooms: name, seats, zone letter.
ROOMS = [
  [ "Берлин", 8, "N" ],
  [ "Осло", 4, "N" ],
  [ "Токио", 6, "S" ],
  [ "Лима", 2, "W" ],
  [ "Порту", 10, "E" ],
  [ "Ханой", 4, "E" ]
]

# --- People -------------------------------------------------------------------
# Every first name is combined with every surname: 10 x 6 = 60 people. Teams
# are dealt out in turn, so each team gets ten people.

FIRST_NAMES = [
  # Russian, latin for the email, gender
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

SURNAMES = [
  # Russian (male form), latin for the email
  [ "Иванов", "ivanov" ],
  [ "Петров", "petrov" ],
  [ "Смирнов", "smirnov" ],
  [ "Кузнецов", "kuznetsov" ],
  [ "Соколов", "sokolov" ],
  [ "Морозов", "morozov" ]
]

# =============================================================================
# BUILD
# =============================================================================

rng = Random.new(RANDOM_SEED)
today = Date.current
days = (0...DAYS_AHEAD).map { |offset| today + offset }

# --- Start from nothing -------------------------------------------------------

Session.delete_all
Booking.delete_all
RecurringSchedule.delete_all
User.delete_all
Resource.delete_all
Team.delete_all
Zone.delete_all

# --- Zones, teams, desks, rooms -----------------------------------------------

zones = ZONES.transform_values { |name| Zone.create!(name: name, floor: FLOOR) }
teams = TEAMS.map { |name, zone_letter| Team.create!(name: name, zone: zones[zone_letter]) }

desk_number = 0
FLOOR_PLAN.each_with_index do |row_letters, row_index|
  row_letters.each_char.with_index do |zone_letter, col_index|
    desk_number += 1
    Resource.create!(
      kind: "desk",
      name: desk_number.to_s,
      zone: zones[zone_letter],
      grid_row: row_index + 1,
      grid_col: col_index + 1
    )
  end
end

ROOMS.each do |name, capacity, zone_letter|
  Resource.create!(kind: "room", name: name, capacity: capacity, zone: zones[zone_letter])
end

desks = Resource.desks.to_a
desks_by_zone = desks.group_by(&:zone_id)
rooms = Resource.rooms.to_a

# --- People -------------------------------------------------------------------

users = []

FIRST_NAMES.each_with_index do |(first_ru, first_lat, gender), first_index|
  SURNAMES.each_with_index do |(surname_ru, surname_lat), surname_index|
    female = gender == :f

    users << User.create!(
      name: "#{first_ru} #{female ? surname_ru + 'а' : surname_ru}",
      email_address: "#{first_lat}.#{surname_lat}#{'a' if female}@office.ru",
      password: PASSWORD,
      team: teams[(first_index + surname_index) % teams.size]
    )
  end
end

main_user = users.find { |user| user.email_address == MAIN_ACCOUNT }
checked_in_user = users.find { |user| user.email_address == CHECKED_IN_ACCOUNT }
released_user = users.find { |user| user.email_address == RELEASED_ACCOUNT }

# Every third person has a favourite desk in their team's zone.
claimed_desk_ids = []
users.each_with_index do |user, index|
  next unless (index % 3).zero?

  desk = desks_by_zone[user.team.zone_id].find { |candidate| !claimed_desk_ids.include?(candidate.id) }
  next if desk.nil?

  claimed_desk_ids << desk.id
  user.update!(default_desk: desk)
end

# --- Recurring schedules ------------------------------------------------------
# The first REGULARS people with a favourite desk come on fixed weekdays: half
# Mon/Wed/Fri, half Tue/Thu. Expanded before the random bookings below, so a
# regular keeps their desk and everyone else fills in around them.

users.select(&:default_desk).first(REGULARS).each_with_index do |user, index|
  schedule = RecurringSchedule.create!(
    user: user,
    resource: user.default_desk,
    weekdays: index.even? ? [ 1, 3, 5 ] : [ 2, 4 ],
    valid_from: today
  )
  schedule.expand!
end

# --- Desk bookings for the days ahead -----------------------------------------
# Attendance falls off towards the end of the week on purpose, so the "who is
# in the office" screen looks different from day to day. A person's own zone
# fills up first, so a team sits together; whoever does not fit lands anywhere
# free — that is the pain this product is about.

days.each_with_index do |date, index|
  taken_desk_ids = Booking.active.on_date(date).pluck(:resource_id)
  busy_user_ids = Booking.active.on_date(date).pluck(:user_id)

  users.shuffle(random: rng).each do |user|
    break if taken_desk_ids.size >= ATTENDANCE_PER_DAY[index]
    next if busy_user_ids.include?(user.id)

    free_by_zone = desks
      .reject { |desk| taken_desk_ids.include?(desk.id) }
      .group_by(&:zone_id)
      .select { |_zone_id, free| free.size > DESKS_KEPT_FREE_PER_ZONE }

    desk = free_by_zone[user.team.zone_id]&.first || free_by_zone.values.flatten.sample(random: rng)
    break if desk.nil?

    Booking.create!(user: user, resource: desk, starts_at: date.beginning_of_day)
    taken_desk_ids << desk.id
    busy_user_ids << user.id
  end
end

# --- Meetings -----------------------------------------------------------------
# Random half-hour and hour-long meetings, a few per room per day. One that
# collides with a meeting already placed is skipped. Meetings whose slot has
# already passed count as attended — the organiser checked in — otherwise every
# past slot of today would look abandoned and the release job would free two
# dozen at once. (clock)

days.each do |date|
  slot_starts = Booking.slot_starts_for(date)

  rooms.each do |room|
    MEETINGS_PER_ROOM_PER_DAY.times do
      first_slot = rng.rand(slot_starts.size - 1)
      length = rng.rand(1..2)
      starts = slot_starts[first_slot, length]
      organizer = users.sample(random: rng)
      group_id = SecureRandom.uuid
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

      meeting.each(&:save!) if meeting.all?(&:valid?)
    end
  end
end

# --- What the main account sees today -----------------------------------------
# She has no desk yet — booking one is done live — her favourite desk is free,
# and at least TEAMMATES_IN_TODAY of her team are in, seated in her zone, so the
# "sit next to a colleague" flow has someone to sit next to.

desk_ids = desks.map(&:id)
teammates = users.select { |user| user.team_id == main_user.team_id && user != main_user }

Booking.active.on_date(today).where(user: main_user, resource_id: desk_ids).delete_all
Booking.active.on_date(today).where(resource_id: main_user.default_desk_id).delete_all

present_ids = Booking.active.on_date(today).where(user: teammates, resource_id: desk_ids).pluck(:user_id)
missing = [ TEAMMATES_IN_TODAY - present_ids.size, 0 ].max

teammates.reject { |user| present_ids.include?(user.id) }.first(missing).each do |teammate|
  taken_ids = Booking.active.on_date(today).pluck(:resource_id)
  desk = desks_by_zone[main_user.team.zone_id].find do |candidate|
    !taken_ids.include?(candidate.id) && candidate.id != main_user.default_desk_id
  end
  next if desk.nil?

  Booking.create!(user: teammate, resource: desk, starts_at: today.beginning_of_day)
end

# --- Three meetings that show auto-release ------------------------------------
# The three stories need three *different* slots that have already started, so
# that clearing the room for one of them does not wipe another. Early in the
# morning fewer than three slots have started; then the first three slots of the
# day are used and the summary warns that the abandoned one is not yet due. (clock)

today_slots = Booking.slot_starts_for(today)
started_slots = today_slots.select { |slot| slot <= Time.current - Booking::RELEASE_AFTER }

released_slot, checked_in_slot, abandoned_slot =
  if started_slots.size >= 3
    # The released one sits in the morning, where the "освободилось" marker is
    # easy to find; the abandoned one is the slot that has just passed.
    [ started_slots.first, started_slots[-2], started_slots.last ]
  else
    today_slots.first(3)
  end

demo_slots = [ released_slot, checked_in_slot, abandoned_slot ]

abandoned_room, checked_in_room, released_room = rooms.first(3)

# All three slots are emptied before anything is written into them: the three
# stories must not delete each other.
Booking.active.where(starts_at: demo_slots, resource: rooms).delete_all

# Booked, started more than ten minutes ago, nobody checked in: this is the one
# `bin/rails office:release` frees during the demo.
Booking.create!(user: main_user, resource: abandoned_room, starts_at: abandoned_slot)

# Checked in, so the same job must leave it alone.
Booking.create!(
  user: checked_in_user,
  resource: checked_in_room,
  starts_at: checked_in_slot,
  state: "checked_in",
  checked_in_at: checked_in_slot
)

# Already released earlier today, so the "освободилось" marker is visible
# without running anything.
Booking.create!(user: released_user, resource: released_room, starts_at: released_slot, state: "released")

# --- Summary: what to show ----------------------------------------------------

teammates_in = Booking.active.on_date(today).where(user: teammates, resource_id: desk_ids).includes(:user, :resource)
account = ->(user, note) { puts "  #{user.email_address.ljust(30)} #{user.name}, #{user.team.name} — #{note}" }

puts "Zones: #{Zone.count}, teams: #{Team.count}, desks: #{Resource.desks.count}, rooms: #{Resource.rooms.count}"
puts "People: #{User.count}, recurring schedules: #{RecurringSchedule.count}"
puts "Bookings: #{Booking.count} (#{Booking.active.desks.on_date(today).count} desks taken today)"
puts
puts "Accounts for the demo (password for everyone: #{PASSWORD}):"
account.call(main_user, "main account: favourite desk #{main_user.default_desk.name} is free, #{teammates_in.size} teammates in today")
account.call(checked_in_user, "checked in to #{checked_in_room.name} at #{checked_in_slot.strftime('%H:%M')}, the release job leaves it alone")
account.call(released_user, "her #{released_room.name} #{released_slot.strftime('%H:%M')} meeting was released, shown as 'освободилось'")
puts "Teammates of #{main_user.name} in the office today (for 'sit next to'):"
teammates_in.each { |booking| account.call(booking.user, "desk #{booking.resource.name}") }
puts "The auto-release story, all on #{today.strftime('%d.%m')}:"
puts "  #{abandoned_room.name} #{abandoned_slot.strftime('%H:%M')} — #{main_user.name}, booked, no check-in: `bin/rails office:release` frees it"
puts "  #{checked_in_room.name} #{checked_in_slot.strftime('%H:%M')} — #{checked_in_user.name}, checked in: the same job leaves it alone"
puts "  #{released_room.name} #{released_slot.strftime('%H:%M')} — #{released_user.name}, already released, shown as 'освободилось'"

if abandoned_slot > Time.current - Booking::RELEASE_AFTER
  due_at = (abandoned_slot + Booking::RELEASE_AFTER).strftime("%H:%M")
  puts "  ! It is #{Time.current.strftime('%H:%M')} and the office day has barely started: the abandoned"
  puts "    booking is only due at #{due_at}, so `bin/rails office:release` frees nothing before then."
end
