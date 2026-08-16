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
  }: {
    date: string
    hours: { open: number; close: number }
    slotMinutes: number
    maxSlots: number
    rooms: CalendarRoom[]
    meetings: CalendarMeeting[]
    releasedSlots: ReleasedSlot[]
    onBook: (roomId: number, startsAt: string, slots: number) => void
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

  // Everyone's meetings, plus two kinds of background hints: slots that were
  // released automatically, and time that has already passed today.
  const events = $derived.by((): Calendar.EventInput[] => {
    const list: Calendar.EventInput[] = meetings.map((meeting) => ({
      id: `meeting-${meeting.id}`,
      resourceId: meeting.room_id,
      start: meeting.starts_at,
      end: meeting.ends_at,
      title: meeting.mine ? (meeting.checked_in ? '✓ вы' : 'вы') : (meeting.person ?? ''),
      classNames: meeting.mine ? (meeting.checked_in ? 'mine checked-in' : 'mine') : 'taken',
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
      // The constraint is checked while a selection grows; the first slot of a
      // selection is not checked, so the callbacks check again before booking.
      selectConstraint: (info) => canBook(Number(info.resource.id), info.start, info.end),
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

<div class="room-calendar overflow-x-auto text-sm">
  <Calendar bind:this={calendar} {plugins} {options}>
    {#snippet resourceLabelContent({ resource })}
      <span class="font-medium">{resource.title}</span>
      <span class="ml-1 text-xs font-normal text-muted-foreground">
        {resource.extendedProps.capacity} мест
      </span>
    {/snippet}
    {#snippet eventContent({ event, timeText })}
      {#if event.display === 'background'}
        <span class="text-[10px]">{event.title}</span>
      {:else}
        <span class="truncate text-xs">{event.title}</span>
        <span class="text-[10px] opacity-80">{timeText}</span>
      {/if}
    {/snippet}
  </Calendar>
</div>

<style>
  /* Map the calendar's own variables onto the app's design tokens so it
     follows the theme, including dark mode. */
  .room-calendar :global(.ec) {
    color-scheme: inherit;
    --ec-bg-color: var(--background);
    --ec-text-color: var(--foreground);
    --ec-border-color: var(--border);
    --ec-today-bg-color: transparent;
    --ec-highlight-color: color-mix(in oklch, var(--primary) 18%, transparent);
    --ec-now-indicator-color: var(--destructive);
    /* Default event colour is what the selection preview is drawn with. */
    --ec-event-bg-color: color-mix(in oklch, var(--primary) 45%, transparent);
    --ec-event-text-color: var(--primary-foreground);
    --ec-bg-event-opacity: 1;
    border-radius: var(--radius);
    overflow: hidden;
  }

  .room-calendar :global(.ec-event) {
    border-radius: calc(var(--radius) - 4px);
    padding: 2px 6px;
    display: flex;
    flex-direction: column;
    gap: 1px;
  }

  .room-calendar :global(.ec-event.mine) {
    --ec-event-bg-color: color-mix(in oklch, var(--primary) 80%, transparent);
  }

  .room-calendar :global(.ec-event.checked-in) {
    --ec-event-bg-color: var(--primary);
  }

  .room-calendar :global(.ec-event.taken) {
    --ec-event-bg-color: var(--muted);
    --ec-event-text-color: var(--muted-foreground);
  }

  .room-calendar :global(.ec-bg-event.released) {
    --ec-bg-event-color: transparent;
    color: var(--muted-foreground);
    padding: 2px 6px;
    text-align: right;
  }

  .room-calendar :global(.ec-bg-event.past) {
    --ec-bg-event-color: var(--muted);
    opacity: 0.6;
  }
</style>
