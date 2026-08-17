<script lang="ts">
  import { router } from '@inertiajs/svelte'
  import { Button, Modal, Tag, Tile } from 'carbon-components-svelte'
  import CheckmarkFilled from 'carbon-icons-svelte/lib/CheckmarkFilled.svelte'
  import Undo from 'carbon-icons-svelte/lib/Undo.svelte'
  import AppLayout from '@/lib/components/AppLayout.svelte'
  import DayStrip from '@/lib/components/DayStrip.svelte'
  import PageHeader from '@/lib/components/PageHeader.svelte'
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

  // Clicking your own block on the grid opens what you can do with it. Kept in
  // the tree so Carbon can put focus back on close; the meeting outlives the
  // close transition so the dialog does not blank while fading out.
  let openMeetingId = $state<number | null>(null)
  let dialogOpen = $state(false)
  const openMeeting = $derived(myMeetings.find((meeting) => meeting.id === openMeetingId) ?? null)

  function book(roomId: number, startsAt: string, slots: number): void {
    router.post(
      '/room_bookings',
      { resource_id: roomId, starts_at: startsAt, slots },
      { preserveScroll: true },
    )
  }

  function checkIn(meeting: Meeting): void {
    dialogOpen = false
    router.post(`/room_bookings/${meeting.id}/check_in`, {}, { preserveScroll: true })
  }

  function cancel(meeting: Meeting): void {
    dialogOpen = false
    router.delete(`/room_bookings/${meeting.id}`, { preserveScroll: true })
  }

  function openDialog(meetingId: number): void {
    openMeetingId = meetingId
    dialogOpen = true
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
  <div class="layout">
    <!-- On a phone your own meetings — and the check-in button — come before
         the calendar; that is what a phone is opened for. -->
    <div class="layout__mine">{@render myBookings()}</div>

    <Tile class="calendar">
      <RoomCalendar
        date={selected_date}
        {hours}
        slotMinutes={slot_minutes}
        maxSlots={max_slots}
        {rooms}
        {meetings}
        releasedSlots={released_slots}
        onBook={book}
        onMeetingClick={openDialog}
      />
    </Tile>

    <aside class="layout__side">
      <div class="side">
        <div class="side__mine">{@render myBookings()}</div>

        <Tile>
          <h2 class="bx--type-productive-heading-01">Обозначения</h2>
          <ul class="legend bx--type-caption-01">
            <li><span class="legend__swatch legend__swatch--free"></span> свободно</li>
            <li><span class="legend__swatch legend__swatch--mine"></span> ваша бронь</li>
            <li><span class="legend__swatch legend__swatch--warn"></span> пора отметиться</li>
            <li><span class="legend__swatch legend__swatch--taken"></span> занято или время прошло</li>
            <li>
              <Undo size={16} aria-hidden="true" />
              «освободилось» — бронь сняли автоматически, никто не отметился
            </li>
          </ul>
        </Tile>
      </div>
    </aside>
  </div>

  <!-- The grid is the whole screen, so the actions for a meeting come to it
       instead of sending the person to the sidebar to find the same row. -->
  <Modal
    open={dialogOpen}
    size="xs"
    passiveModal
    selectorPrimaryFocus=".bx--modal-close"
    modalHeading={openMeeting ? `${openMeeting.room_name}, ${time(openMeeting.starts_at)}–${time(openMeeting.ends_at)}` : ''}
    on:close={() => (dialogOpen = false)}
  >
    {#if openMeeting}
      <p class="bx--type-body-long-01">
        {#if openMeeting.checked_in}
          Вы отметились — эта бронь останется за вами.
        {:else if openMeeting.can_check_in}
          Отметьтесь, иначе бронь снимется и комната вернётся в общий доступ.
        {:else}
          Отметиться можно с {time(openMeeting.check_in_opens_at)}. Без отметки бронь снимется.
        {/if}
      </p>

      <div class="dialog__actions">
        {#if !openMeeting.checked_in && openMeeting.can_check_in}
          <Button size="small" icon={CheckmarkFilled} onclick={() => checkIn(openMeeting)}>
            Отметиться
          </Button>
        {/if}
        <Button kind="danger-tertiary" size="small" onclick={() => cancel(openMeeting)}>
          Отменить встречу
        </Button>
      </div>
    {/if}
  </Modal>

  <Toast message={error} />
</AppLayout>

{#snippet myBookings()}
  <Tile>
    <h2 class="bx--type-productive-heading-01">Ваши брони</h2>

    {#if myMeetings.length === 0}
      <p class="side__hint bx--type-body-long-01">На этот день броней нет.</p>
    {:else}
      <ul class="bookings">
        {#each myMeetings as meeting (meeting.id)}
          <li>
            <p class="bookings__when">
              <strong>{meeting.room_name}</strong>
              <span>{time(meeting.starts_at)}–{time(meeting.ends_at)}</span>
            </p>

            <div class="bookings__actions">
              {#if meeting.checked_in}
                <Tag type="green" icon={CheckmarkFilled}>вы отметились</Tag>
              {:else if meeting.can_check_in}
                <Button size="small" icon={CheckmarkFilled} onclick={() => checkIn(meeting)}>
                  Отметиться
                </Button>
              {:else}
                <span class="side__hint bx--type-helper-text-01">
                  отметиться можно с {time(meeting.check_in_opens_at)}
                </span>
              {/if}

              <Button kind="ghost" size="small" onclick={() => cancel(meeting)}>Отменить</Button>
            </div>
          </li>
        {/each}
      </ul>
    {/if}
  </Tile>
{/snippet}

<style>
  .layout {
    margin-block-start: var(--cds-spacing-06);
    display: grid;
    gap: var(--cds-spacing-05);
  }

  :global(.calendar) {
    padding: var(--cds-spacing-03);
    min-width: 0;
  }

  .side {
    display: grid;
    gap: var(--cds-spacing-05);
    align-content: start;
  }

  .side :global(.bx--tile),
  .layout__mine :global(.bx--tile) {
    display: grid;
    justify-items: start;
    gap: var(--cds-spacing-03);
  }

  .side__mine {
    display: none;
  }

  .side__hint {
    color: var(--cds-text-02);
  }

  .bookings {
    display: grid;
    gap: var(--cds-spacing-05);
    width: 100%;
  }

  .bookings li + li {
    border-block-start: 1px solid var(--cds-ui-03);
    padding-block-start: var(--cds-spacing-05);
  }

  .bookings__when {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    gap: var(--cds-spacing-03);
  }

  .bookings__when span {
    color: var(--cds-text-02);
    font-variant-numeric: tabular-nums;
  }

  .bookings__actions {
    margin-block-start: var(--cds-spacing-03);
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: var(--cds-spacing-03);
  }

  .dialog__actions {
    margin-block-start: var(--cds-spacing-06);
    display: flex;
    flex-wrap: wrap;
    gap: var(--cds-spacing-03);
  }

  .legend {
    display: grid;
    gap: var(--cds-spacing-03);
    color: var(--cds-text-02);
  }

  .legend li {
    display: flex;
    align-items: flex-start;
    gap: var(--cds-spacing-03);
  }

  .legend :global(svg) {
    flex-shrink: 0;
    fill: var(--cds-text-03);
  }

  .legend__swatch {
    width: 1rem;
    height: 1rem;
    flex-shrink: 0;
    border: 1px solid var(--cds-ui-04);
  }

  .legend__swatch--free {
    background-color: var(--cds-ui-01);
  }

  .legend__swatch--mine {
    background-color: var(--cds-interactive-01);
    border-color: var(--cds-interactive-01);
  }

  .legend__swatch--warn {
    background-color: var(--cds-support-03);
    border-color: var(--cds-support-03);
  }

  .legend__swatch--taken {
    background-color: var(--cds-ui-03);
    border-color: var(--cds-ui-03);
  }

  /* The sidebar moves beside the calendar where Carbon expects two columns. */
  @media (min-width: 66rem) {
    .layout {
      grid-template-columns: minmax(0, 1fr) 18rem;
      align-items: start;
      gap: var(--cds-spacing-06);
    }

    .layout__mine {
      display: none;
    }

    .side__mine {
      display: block;
    }
  }
</style>
