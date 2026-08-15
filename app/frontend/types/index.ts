export type FlashData = {
  notice?: string
  alert?: string
}

export type CurrentUser = {
  id: number
  name: string
  team_name: string
  zone_name: string
}

export type SharedProps = {
  current_user: CurrentUser | null
}
