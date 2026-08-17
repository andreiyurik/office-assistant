<script lang="ts">
  import type { Snippet } from 'svelte'
  import { page, router } from '@inertiajs/svelte'
  import {
    Content,
    Header,
    HeaderAction,
    HeaderGlobalAction,
    HeaderNav,
    HeaderNavItem,
    HeaderPanelDivider,
    HeaderPanelLink,
    HeaderPanelLinks,
    HeaderUtilities,
    InlineNotification,
    NotificationActionButton,
    SideNav,
    SideNavItems,
    SideNavLink,
    SkipToContent,
  } from 'carbon-components-svelte'
  import Calendar from 'carbon-icons-svelte/lib/Calendar.svelte'
  import Grid from 'carbon-icons-svelte/lib/Grid.svelte'
  import UserAvatar from 'carbon-icons-svelte/lib/UserAvatar.svelte'
  import UserMultiple from 'carbon-icons-svelte/lib/UserMultiple.svelte'
  import { time } from '@/lib/format'
  import { visitOnClick } from '@/lib/visit'
  import type { CurrentUser, PendingCheckIn } from '@/types'

  let { children }: { children: Snippet } = $props()

  // Both come from the shared props every controller sends.
  const user = $derived(page.props.current_user as CurrentUser)
  const pending = $derived(page.props.pending_check_in as PendingCheckIn | null)

  // The Header owns this: it opens the SideNav from the hamburger below the
  // large breakpoint, where HeaderNav is hidden.
  let isSideNavOpen = $state(false)
  let isProfileOpen = $state(false)

  const links = [
    { href: '/', label: 'Кто в офисе', icon: UserMultiple },
    { href: '/desks', label: 'Карта мест', icon: Grid },
    { href: '/rooms', label: 'Переговорные', icon: Calendar },
  ]

  function isActive(href: string): boolean {
    const path = page.url.split('?')[0]
    return href === '/' ? path === '/' : path.startsWith(href)
  }

  function releaseIn(iso: string): string {
    const minutes = Math.round((new Date(iso).getTime() - Date.now()) / 60000)
    return minutes <= 0 ? 'вот-вот' : `через ${minutes} мин`
  }

  function checkIn(id: number): void {
    router.post(`/room_bookings/${id}/check_in`, {}, { preserveScroll: true })
  }

  function signOut(): void {
    router.delete('/session')
  }
</script>

<!-- expandedByDefault={false} keeps the SideNav shut on a wide screen: above the
     large breakpoint the HeaderNav is the navigation, and letting Carbon expand
     the rail as well would put the same three links on screen twice. -->
<Header
  companyName="Macrohard"
  platformName="Office Assistant"
  href="/"
  onclick={visitOnClick('/')}
  expandedByDefault={false}
  bind:isSideNavOpen
>
  {#snippet skipToContent()}
    <SkipToContent />
  {/snippet}

  <HeaderNav>
    {#each links as link (link.href)}
      <HeaderNavItem
        href={link.href}
        text={link.label}
        isSelected={isActive(link.href)}
        onclick={visitOnClick(link.href)}
      />
    {/each}
  </HeaderNav>

  <HeaderUtilities>
    <!-- Who you are and the way out live in one panel, which is where Carbon
         puts the account. The name has to be visible somewhere: the demo has
         five logins and they differ only by which one is signed in. -->
    <HeaderAction bind:isOpen={isProfileOpen} icon={UserAvatar} text={user.name}>
      <HeaderPanelLinks>
        <HeaderPanelDivider>{user.team_name}</HeaderPanelDivider>
        <HeaderPanelLink href="/session" onclick={(event: MouseEvent) => { event.preventDefault(); signOut() }}>
          Выйти
        </HeaderPanelLink>
      </HeaderPanelLinks>
    </HeaderAction>
  </HeaderUtilities>
</Header>

<SideNav bind:isOpen={isSideNavOpen} ariaLabel="Разделы">
  <SideNavItems>
    {#each links as link (link.href)}
      <SideNavLink
        href={link.href}
        text={link.label}
        icon={link.icon}
        isSelected={isActive(link.href)}
        onclick={visitOnClick(link.href)}
      />
    {/each}
  </SideNavItems>
</SideNav>

<Content>
  <!-- Auto-release only works if confirming is easy, so the prompt follows the
       person onto whichever of the three screens they opened. It sits above
       the page title, in the flow, so nothing below it moves when it appears. -->
  {#if pending}
    <div class="check-in">
      <InlineNotification
        kind="warning"
        lowContrast
        hideCloseButton
        title="Отметьтесь на встрече:"
        subtitle="{pending.room_name}, {time(pending.starts_at)}. Без подтверждения бронь снимется {releaseIn(
          pending.releases_at,
        )}."
      >
        {#snippet actions()}
          <NotificationActionButton onclick={() => checkIn(pending!.id)}>
            Отметиться
          </NotificationActionButton>
        {/snippet}
      </InlineNotification>
    </div>
  {/if}

  {@render children()}
</Content>

<style>
  /* The lockup lives in a 48px bar next to a person's full name. It must not
     wrap: "Macrohard Office Assistant" beside "Екатерина Кузнецова" broke onto
     two lines inside the header. Below Carbon's medium breakpoint the company
     prefix steps aside — on a phone the product name is what identifies the
     screen, and the company is on the login page anyway.
     Global because the header is Carbon's own markup, and there is one. */
  :global(.bx--header__name) {
    white-space: nowrap;
  }

  @media (max-width: 41.99rem) {
    :global(.bx--header__name--prefix) {
      display: none;
    }
  }

  /* Carbon gives the notification a fixed min-width meant for a narrow column;
     across the top of a page it should use the width it has. */
  .check-in :global(.bx--inline-notification) {
    max-width: 100%;
    margin-block: 0 var(--cds-spacing-06);
  }
</style>
