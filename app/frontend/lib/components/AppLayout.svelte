<script lang="ts">
  import type { Snippet } from 'svelte'
  import { Link, page } from '@inertiajs/svelte'
  import type { CurrentUser } from '@/types'

  let { current_user, children }: { current_user: CurrentUser; children: Snippet } = $props()

  const links = [
    { href: '/', label: 'Кто в офисе' },
    { href: '/desks', label: 'Карта мест' },
    { href: '/rooms', label: 'Переговорные' },
  ]

  function isActive(href: string): boolean {
    const path = page.url.split('?')[0]
    return href === '/' ? path === '/' : path.startsWith(href)
  }
</script>

<div class="min-h-screen bg-background text-foreground">
  <header class="sticky top-0 z-10 border-b bg-background/95 backdrop-blur">
    <div class="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-2.5">
      <nav class="flex items-center gap-1">
        <span class="mr-2 hidden text-sm font-semibold tracking-tight sm:inline">Office Assistant</span>

        {#each links as link (link.href)}
          <Link
            href={link.href}
            class="rounded-md px-3 py-1.5 text-sm font-medium transition-colors {isActive(link.href)
              ? 'bg-secondary text-secondary-foreground'
              : 'text-muted-foreground hover:text-foreground'}"
          >
            {link.label}
          </Link>
        {/each}
      </nav>

      <div class="flex items-center gap-3">
        <div class="text-right leading-tight">
          <div class="text-sm font-medium">{current_user.name}</div>
          <div class="text-xs text-muted-foreground">{current_user.team_name}</div>
        </div>
        <Link
          href="/session"
          method="delete"
          as="button"
          class="rounded-md px-2 py-1.5 text-sm text-muted-foreground transition-colors hover:text-foreground"
        >
          Выйти
        </Link>
      </div>
    </div>
  </header>

  <main class="mx-auto max-w-6xl px-4 py-6">
    {@render children()}
  </main>
</div>
