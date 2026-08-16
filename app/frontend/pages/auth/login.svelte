<script lang="ts">
  import { Form } from '@inertiajs/svelte'
  import { firstError } from '@/lib/format'
  import { Button } from '@/lib/components/ui/button'
  import BrandMark from '@/lib/components/BrandMark.svelte'

  let { errors = {} }: { errors?: Record<string, string[] | string> } = $props()

  const error = $derived(firstError(errors))
</script>

<svelte:head>
  <title>Вход — Office Assistant</title>
</svelte:head>

<div class="flex min-h-screen items-center justify-center bg-muted/40 px-4 py-10">
  <div class="w-full max-w-sm">
    <div class="flex items-center gap-3">
      <BrandMark class="size-9" />
      <div>
        <h1 class="text-xl font-semibold tracking-tight">Office Assistant</h1>
        <p class="text-sm text-muted-foreground">Места, переговорные, кто в офисе</p>
      </div>
    </div>

    <Form action="/session" method="post" class="mt-6 space-y-4 rounded-2xl border bg-card p-6 shadow-sm">
      {#if error}
        <p role="alert" class="rounded-md border border-destructive/20 bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {error}
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
          placeholder="имя.фамилия@office.ru"
          class="h-10 w-full rounded-md border border-input bg-background px-3 text-sm outline-none placeholder:text-muted-foreground/70 focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/30"
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
          class="h-10 w-full rounded-md border border-input bg-background px-3 text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/30"
        />
      </div>

      <Button type="submit" size="lg" class="w-full">Войти</Button>
    </Form>
  </div>
</div>
