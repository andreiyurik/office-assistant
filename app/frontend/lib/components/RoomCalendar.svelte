<script module lang="ts">
  // Prop types live here so the page that renders the calendar can import them.
  export type CalendarRoom = {
    id: number
    name: string
    capacity: number
  }

  export type CalendarMeeting = {
    id: number
    room_id: number
    starts_at: string
    ends_at: string
    mine: boolean
    person: string | null
    checked_in: boolean
    can_check_in: boolean
  }

  export type ReleasedSlot = {
    room_id: number
    starts_at: string
    ends_at: string
  }
</script>

<script lang="ts">
  import { Calendar, ResourceTimeGrid, Interaction } from '@event-calendar/core'

  let {
    date,
    hours,
    slotMinutes,
    maxSlots,
    rooms,
    meetings,
    releasedSlots,
    onBook,
    onMeetingClick,
  }: {
    date: string
    hours: { open: number; close: number }
    slotMinutes: number
    maxSlots: number
    rooms: CalendarRoom[]
    meetings: CalendarMeeting[]
    releasedSlots: ReleasedSlot[]
    onBook: (roomId: number, startsAt: string, slots: number) => void
    onMeetingClick: (meetingId: number) => void
  } = $props()

  const plugins = [ResourceTimeGrid, Interaction]
  // The component instance exposes the same methods as createCalendar() —
  // unselect() among them — but the package types do not declare that.
  let calendar: ReturnType<typeof Calendar> | undefined = $state()
  const slotMs = $derived(slotMinutes * 60_000)

  // The current slot is still bookable until it ends, so "past" starts at
  // the beginning of the slot that is happening now.
  function pastUntil(): Date {
    const now = new Date()
    now.setSeconds(0, 0)
    now.setMinutes(now.getMinutes() - (now.getMinutes() % slotMinutes))
    return now
  }

  // Only this room's meetings block a slot here. Being booked elsewhere at
  // the same time is left to the server, whose message says what to do about it.
  function overlapsMeeting(roomId: number, start: Date, end: Date): boolean {
    return meetings.some(
      (meeting) =>
        meeting.room_id === roomId &&
        new Date(meeting.starts_at) < end &&
        new Date(meeting.ends_at) > start,
    )
  }

  function canBook(roomId: number, start: Date, end: Date): boolean {
    if (start < pastUntil()) return false
    if (end.getTime() - start.getTime() > maxSlots * slotMs) return false
    return !overlapsMeeting(roomId, start, end)
  }

  // My meeting has three looks: booked, waiting for my check-in (the window is
  // open and the clock is running), and checked in.
  function myClasses(meeting: CalendarMeeting): string {
    if (meeting.checked_in) return 'mine checked-in'
    if (meeting.can_check_in) return 'mine needs-check-in'
    return 'mine'
  }

  function myTitle(meeting: CalendarMeeting): string {
    if (meeting.checked_in) return '✓ вы'
    if (meeting.can_check_in) return 'вы — отметьтесь'
    return 'вы'
  }

  // Everyone's meetings, plus two kinds of background hints: slots that were
  // released automatically, and time that has already passed today.
  const events = $derived.by((): Calendar.EventInput[] => {
    const list: Calendar.EventInput[] = meetings.map((meeting) => ({
      id: `meeting-${meeting.id}`,
      resourceId: meeting.room_id,
      start: meeting.starts_at,
      end: meeting.ends_at,
      title: meeting.mine ? myTitle(meeting) : (meeting.person ?? ''),
      classNames: meeting.mine ? myClasses(meeting) : 'taken',
      extendedProps: { person: meeting.person, meetingId: meeting.id, mine: meeting.mine },
    }))

    for (const slot of releasedSlots) {
      list.push({
        id: `released-${slot.room_id}-${slot.starts_at}`,
        resourceId: slot.room_id,
        start: slot.starts_at,
        end: slot.ends_at,
        title: 'освободилось',
        display: 'background',
        classNames: 'released',
      })
    }

    const dayStart = new Date(`${date}T00:00:00`)
    const past = pastUntil()
    if (past > dayStart) {
      const dayEnd = new Date(dayStart.getTime() + 24 * 60 * 60_000)
      for (const room of rooms) {
        list.push({
          id: `past-${room.id}`,
          resourceId: room.id,
          start: dayStart,
          end: past < dayEnd ? past : dayEnd,
          display: 'background',
          classNames: 'past',
        })
      }
    }

    return list
  })

  const options = $derived.by(
    (): Calendar.Options => ({
      view: 'resourceTimeGridDay',
      date,
      resources: rooms.map((room) => ({
        id: room.id,
        title: room.name,
        extendedProps: { capacity: room.capacity },
      })),
      events,
      headerToolbar: { start: '', center: '', end: '' },
      allDaySlot: false,
      slotDuration: { minutes: slotMinutes },
      slotMinTime: `${String(hours.open).padStart(2, '0')}:00`,
      slotMaxTime: `${String(hours.close).padStart(2, '0')}:00`,
      slotHeight: 32,
      // Columns share the width, but never shrink below what a name needs;
      // on a phone the calendar scrolls sideways instead of squeezing.
      columnWidth: 'minmax(7rem, 1fr)',
      height: 'auto',
      locale: 'ru-RU',
      slotLabelFormat: { hour: '2-digit', minute: '2-digit' },
      eventTimeFormat: { hour: '2-digit', minute: '2-digit' },
      nowIndicator: true,
      pointer: true,
      selectable: true,
      // Names get cut in a narrow column; the full one is in the tooltip.
      eventDidMount: (info) => {
        const person = info.event.extendedProps.person
        if (typeof person === 'string' && person) info.el.title = `${person}, ${info.timeText}`
      },
      // The constraint is checked while a selection grows; the first slot of a
      // selection is not checked, so the callbacks check again before booking.
      selectConstraint: (info) => canBook(Number(info.resource.id), info.start, info.end),
      // Your own meeting is the one block on the grid that has actions behind
      // it; everyone else's is just occupied time.
      eventClick: (info) => {
        const { mine, meetingId } = info.event.extendedProps
        if (mine && typeof meetingId === 'number') onMeetingClick(meetingId)
      },
      // A click is one slot, a drag is several — both end up in the same place.
      dateClick: (info) => {
        if (!info.resource) return
        const end = new Date(info.date.getTime() + slotMs)
        const roomId = Number(info.resource.id)
        if (canBook(roomId, info.date, end)) onBook(roomId, info.date.toISOString(), 1)
      },
      select: (info) => {
        const roomId = Number(info.resource.id)
        const slots = Math.round((info.end.getTime() - info.start.getTime()) / slotMs)
        if (canBook(roomId, info.start, info.end)) onBook(roomId, info.start.toISOString(), slots)
        // Either the booking shows up as an event or an error is shown;
        // the selection highlight has done its job either way.
        const instance = calendar as Calendar | undefined
        instance?.unselect()
      },
    }),
  )
</script>

<div class="room-calendar">
  <Calendar bind:this={calendar} {plugins} {options}>
    {#snippet resourceLabelContent({ resource })}
      <span class="room">{resource.title}</span>
      <span class="room-capacity">{resource.extendedProps.capacity} мест</span>
    {/snippet}
    <!-- A single slot is 32px tall and two lines of text need 36, so the time
         only appears on a meeting long enough to hold it. On a half-hour block
         the row it sits in already says when it is. -->
    {#snippet eventContent({ event, timeText })}
      {#if event.display === 'background'}
        <span class="event-note">{event.title}</span>
      {:else}
        <span class="event-title">{event.title}</span>
        {#if event.end.getTime() - event.start.getTime() > slotMs}
          <span class="event-time">{timeText}</span>
        {/if}
      {/if}
    {/snippet}
  </Calendar>
</div>

<style>
  /* The calendar is the one part of the screen Carbon does not draw, so its own
     variables are pointed at Carbon tokens. Nothing here is a colour: every
     value is the token a Carbon component would use in the same place. */
  .room-calendar :global(.ec) {
    --ec-bg-color: var(--cds-ui-01);
    --ec-text-color: var(--cds-text-01);
    --ec-border-color: var(--cds-ui-03);
    --ec-today-bg-color: transparent;
    --ec-highlight-color: var(--cds-highlight);
    --ec-now-indicator-color: var(--cds-support-01);
    /* The default event colour is what the drag preview is drawn with. */
    --ec-event-bg-color: var(--cds-interactive-01);
    --ec-event-text-color: var(--cds-text-04);
    --ec-bg-event-opacity: 1;
    /* The library keeps a gutter beside an event so two overlapping ones can
       sit side by side. A room cannot be double-booked here, so the gutter is
       dead space: blocks fill their column and the grid reads busy or free. */
    --ec-event-col-gap: 0;
    font-family: inherit;
  }

  /* Hour labels sit just below their line instead of centred on it, so the
     first one (09:00) fits under the header — the library hides it otherwise. */
  .room-calendar :global(.ec-body .ec-sidebar .ec-slot) {
    inset-block-start: var(--cds-spacing-02);
  }
  .room-calendar :global(.ec-body .ec-sidebar .ec-slot.ec-hidden) {
    visibility: visible;
  }

  /* Now that blocks fill their column the indicator always crosses one, and a
     2px saturated line through 14px text is hard to read past. One pixel is
     Carbon's divider weight and the dot at the edge still marks the hour. */
  .room-calendar :global(.ec-time-grid .ec-now-indicator) {
    border-block-start-width: 1px;
  }

  /* Carbon has no rounded corners anywhere, so neither does an event. */
  .room-calendar :global(.ec-event) {
    border-radius: 0;
    padding: var(--cds-spacing-01) var(--cds-spacing-03);
    display: flex;
    flex-direction: column;
    gap: 1px;
  }

  /* Your own meetings are the only blocks with actions behind them. */
  .room-calendar :global(.ec-event.mine) {
    --ec-event-bg-color: var(--cds-interactive-01);
    cursor: pointer;
  }

  .room-calendar :global(.ec-event.checked-in) {
    --ec-event-bg-color: var(--cds-support-02);
  }

  /* The check-in window is open and nobody has confirmed. Carbon's warning
     token, and its dark text — yellow carries no white text anywhere in Carbon. */
  .room-calendar :global(.ec-event.needs-check-in) {
    --ec-event-bg-color: var(--cds-support-03);
    --ec-event-text-color: var(--cds-text-01);
  }

  .room-calendar :global(.ec-event.taken) {
    --ec-event-bg-color: var(--cds-ui-03);
    --ec-event-text-color: var(--cds-text-02);
  }

  .room-calendar :global(.ec-bg-event.released) {
    --ec-bg-event-color: transparent;
    color: var(--cds-text-02);
    padding: var(--cds-spacing-01) var(--cds-spacing-03);
    text-align: right;
  }

  .room-calendar :global(.ec-bg-event.past) {
    --ec-bg-event-color: var(--cds-ui-02);
  }

  /* Room names read as column headers, so they get the table header surface. */
  .room-calendar :global(.ec-header) {
    background-color: var(--cds-ui-03);
  }

  /* Six rooms do not fit a phone; the grid scrolls sideways rather than
     squeezing the columns past legibility. */
  .room-calendar {
    overflow-x: auto;
  }

  .room-calendar :global(.room) {
    font-weight: 600;
  }

  .room-calendar :global(.room-capacity) {
    margin-inline-start: var(--cds-spacing-02);
    font-weight: 400;
    color: var(--cds-text-02);
  }

  .room-calendar :global(.event-title) {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .room-calendar :global(.event-time),
  .room-calendar :global(.event-note) {
    font-size: var(--cds-caption-01-font-size);
  }

  /* No opacity here: on a taken block it took the time under 4.5:1. The event
     already sets its own text colour, and the smaller size carries the rank. */
  .room-calendar :global(.event-time) {
    color: inherit;
  }
</style>
