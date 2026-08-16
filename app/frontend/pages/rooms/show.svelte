<script lang="ts">
  import { router } from '@inertiajs/svelte'
  import AppLayout from '@/lib/components/AppLayout.svelte'
  import DayStrip from '@/lib/components/DayStrip.svelte'
  import PageHeader from '@/lib/components/PageHeader.svelte'
  import Toast from '@/lib/components/Toast.svelte'
  import { Button } from '@/lib/components/ui/button'
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
  <PageHeader
    title="Переговорные"
    description="Нажмите на свободное время — это {slot_minutes} минут. Протяните вниз, чтобы занять до {(max_slots * slot_minutes) / 60} ч подряд."
  >
    <DayStrip {days} selected={selected_date} hrefFor={(day) => `/rooms?date=${day}`} />
  </PageHeader>

  <!-- The calendar keeps its place: everything that appears and disappears —
       bookings, hints, messages — lives in the sidebar or floats above. -->
  <div class="mt-6 flex flex-col items-start gap-6 lg:flex-row">
    <!-- On a phone your own meetings — and the check-in button — come before
         the calendar; that is what a phone is opened for. -->
    <div class="w-full lg:hidden">{@render myBookings()}</div>

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

    <aside class="w-full shrink-0 space-y-3 lg:w-72">
      <div class="hidden lg:block">{@render myBookings()}</div>

      <section class="space-y-2 rounded-xl border bg-card p-4 text-xs text-muted-foreground">
        <span class="flex items-center gap-2">
          <span class="size-3.5 rounded border bg-background"></span> свободно
        </span>
        <span class="flex items-center gap-2">
          <span class="size-3.5 rounded bg-primary"></span> ваша бронь
        </span>
        <span class="flex items-center gap-2">
          <span class="size-3.5 rounded bg-muted"></span> занято или время прошло
        </span>
        <p class="pt-1">«освободилось» — бронь сняли автоматически, никто не отметился.</p>
      </section>
    </aside>
  </div>

  <Toast message={error} />
</AppLayout>

{#snippet myBookings()}
  <section class="rounded-xl border bg-card p-4">
    <h2 class="text-sm font-semibold">Ваши брони</h2>

    {#if myMeetings.length === 0}
      <p class="mt-1 text-sm text-muted-foreground">На этот день броней нет.</p>
    {:else}
      <ul class="mt-3 divide-y">
        {#each myMeetings as meeting (meeting.id)}
          <li class="py-3 first:pt-0 last:pb-0">
            <p class="flex items-center gap-2 text-sm">
              <span
                class="size-2 rounded-full {meeting.checked_in ? 'bg-success' : 'bg-primary'}"
                aria-hidden="true"
              ></span>
              <span class="font-medium">{meeting.room_name}</span>
              <span class="text-muted-foreground tabular-nums">{time(meeting.starts_at)}–{time(meeting.ends_at)}</span>
            </p>

            <div class="mt-2 flex flex-wrap items-center gap-2">
              {#if meeting.checked_in}
                <span class="text-xs text-success">вы отметились</span>
              {:else if meeting.can_check_in}
                <Button size="sm" onclick={() => checkIn(meeting)}>Отметиться</Button>
              {:else}
                <span class="text-xs text-muted-foreground">
                  отметиться можно с {time(meeting.check_in_opens_at)}
                </span>
              {/if}

              <Button variant="ghost" size="sm" class="text-muted-foreground" onclick={() => cancel(meeting)}>
                Отменить
              </Button>
            </div>
          </li>
        {/each}
      </ul>
    {/if}
  </section>
{/snippet}
