<script lang="ts">
  import { router } from '@inertiajs/svelte'
  import AppLayout from '@/lib/components/AppLayout.svelte'
  import DayStrip from '@/lib/components/DayStrip.svelte'
  import Toast from '@/lib/components/Toast.svelte'
  import { firstError, time } from '@/lib/format'
  import RoomCalendar, {
    type CalendarRoom,
    type CalendarMeeting,
    type ReleasedSlot,
  } from '@/lib/components/RoomCalendar.svelte'

  // A meeting as the sidebar sees it: the calendar fields plus what is needed
  // to check in or cancel.
  type Meeting = CalendarMeeting & {
    room_name: string
    can_check_in: boolean
    check_in_opens_at: string
  }

  let {
    selected_date,
    days,
    hours,
    slot_minutes,
    max_slots,
    rooms,
    meetings,
    released_slots,
    errors = {},
  }: {
    selected_date: string
    days: string[]
    hours: { open: number; close: number }
    slot_minutes: number
    max_slots: number
    rooms: CalendarRoom[]
    meetings: Meeting[]
    released_slots: ReleasedSlot[]
    errors?: Record<string, string[] | string>
  } = $props()

  const myMeetings = $derived(meetings.filter((meeting) => meeting.mine))

  const error = $derived(firstError(errors))

  function book(roomId: number, startsAt: string, slots: number): void {
    router.post(
      '/room_bookings',
      { resource_id: roomId, starts_at: startsAt, slots },
      { preserveScroll: true },
    )
  }

  function checkIn(meeting: Meeting): void {
    router.post(`/room_bookings/${meeting.id}/check_in`, {}, { preserveScroll: true })
  }

  function cancel(meeting: Meeting): void {
    router.delete(`/room_bookings/${meeting.id}`, { preserveScroll: true })
  }
</script>

<svelte:head>
  <title>Переговорные — Office Assistant</title>
</svelte:head>

<AppLayout>
  <div class="flex flex-wrap items-end justify-between gap-3">
    <h1 class="text-xl font-semibold tracking-tight">Переговорные</h1>
    <DayStrip {days} selected={selected_date} hrefFor={(day) => `/rooms?date=${day}`} />
  </div>

  <!-- The calendar keeps its place: everything that appears and disappears —
       bookings, hints, messages — lives in the sidebar or floats above. -->
  <div class="mt-4 flex flex-col items-start gap-4 md:flex-row">
    <div class="w-full min-w-0 flex-1">
      <RoomCalendar
        date={selected_date}
        {hours}
        slotMinutes={slot_minutes}
        maxSlots={max_slots}
        {rooms}
        {meetings}
        releasedSlots={released_slots}
        onBook={book}
      />
    </div>

    <aside class="w-full shrink-0 space-y-3 md:w-64">
      <section class="rounded-lg border p-3">
        <h2 class="text-sm font-medium">Как забронировать</h2>
        <p class="mt-1 text-xs text-muted-foreground">
          Нажмите на свободное время — это {slot_minutes} минут. Протяните вниз, чтобы занять
          больше: до {(max_slots * slot_minutes) / 60} ч подряд.
        </p>
      </section>

      <section class="rounded-lg border p-3">
        <h2 class="text-sm font-medium">Ваши брони</h2>

        {#if myMeetings.length === 0}
          <p class="mt-1 text-xs text-muted-foreground">На этот день броней нет.</p>
        {:else}
          <ul class="mt-2 space-y-3">
            {#each myMeetings as meeting (meeting.id)}
              <li>
                <p class="text-sm">
                  <span class="font-medium">{meeting.room_name}</span>
                  · {time(meeting.starts_at)}–{time(meeting.ends_at)}
                </p>

                <div class="mt-1 flex flex-wrap items-center gap-2">
                  {#if meeting.checked_in}
                    <span class="text-xs text-muted-foreground">вы отметились</span>
                  {:else if meeting.can_check_in}
                    <button
                      type="button"
                      onclick={() => checkIn(meeting)}
                      class="rounded-md bg-primary px-2 py-1 text-xs font-medium text-primary-foreground transition-colors hover:bg-primary/80"
                    >
                      Отметиться
                    </button>
                  {:else}
                    <span class="text-xs text-muted-foreground">
                      отметиться с {time(meeting.check_in_opens_at)}
                    </span>
                  {/if}

                  <button
                    type="button"
                    onclick={() => cancel(meeting)}
                    class="text-xs text-muted-foreground underline underline-offset-4 hover:text-foreground"
                  >
                    Отменить
                  </button>
                </div>
              </li>
            {/each}
          </ul>
        {/if}
      </section>

      <section class="space-y-1.5 rounded-lg border p-3 text-xs text-muted-foreground">
        <span class="flex items-center gap-1.5">
          <span class="size-3 rounded border bg-background"></span> свободно
        </span>
        <span class="flex items-center gap-1.5">
          <span class="size-3 rounded bg-primary"></span> ваша бронь
        </span>
        <span class="flex items-center gap-1.5">
          <span class="size-3 rounded bg-muted"></span> занято или время прошло
        </span>
        <p>«освободилось» — бронь сняли автоматически, никто не отметился</p>
      </section>
    </aside>
  </div>

  <Toast message={error} />
</AppLayout>
