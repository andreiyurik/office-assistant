<script lang="ts">
  import AppLayout from '@/lib/components/AppLayout.svelte'
  import type { CurrentUser } from '@/types'

  let { current_user }: { current_user: CurrentUser } = $props()
</script>

<svelte:head>
  <title>Кто в офисе — Office Assistant</title>
</svelte:head>

<AppLayout {current_user}>
  <h1 class="text-xl font-semibold tracking-tight">Кто сегодня в офисе</h1>
</AppLayout>
