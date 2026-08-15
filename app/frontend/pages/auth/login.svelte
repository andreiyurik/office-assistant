<script lang="ts">
  import { Form } from '@inertiajs/svelte'
  import { Button } from '@/lib/components/ui/button'

  let { errors = {} }: { errors?: Record<string, string[] | string> } = $props()

  function message(value: string[] | string | undefined): string | null {
    if (!value) return null
    return Array.isArray(value) ? value[0] : value
  }
</script>

<svelte:head>
  <title>Вход — Office Assistant</title>
</svelte:head>

<div class="flex min-h-screen items-center justify-center bg-muted/30 px-4">
  <div class="w-full max-w-sm">
    <h1 class="text-2xl font-semibold tracking-tight">Office Assistant</h1>
    <p class="mt-1 text-sm text-muted-foreground">Бронирование мест и переговорных</p>

    <Form action="/session" method="post" class="mt-6 space-y-4">
      {#if message(errors.login)}
        <p class="rounded-md bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {message(errors.login)}
        </p>
      {/if}

      <div class="space-y-1.5">
        <label for="email_address" class="text-sm font-medium">Рабочая почта</label>
        <!-- svelte-ignore a11y_autofocus -->
        <input
          id="email_address"
          name="email_address"
          type="email"
          required
          autofocus
          autocomplete="username"
          class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm outline-none focus-visible:ring-2 focus-visible:ring-ring"
        />
      </div>

      <div class="space-y-1.5">
        <label for="password" class="text-sm font-medium">Пароль</label>
        <input
          id="password"
          name="password"
          type="password"
          required
          autocomplete="current-password"
          maxlength="72"
          class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm outline-none focus-visible:ring-2 focus-visible:ring-ring"
        />
      </div>

      <Button type="submit" class="w-full">Войти</Button>
    </Form>
  </div>
</div>
