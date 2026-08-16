import { router, shouldIntercept } from '@inertiajs/core'

// Carbon's navigation components render their own <a>, so Inertia's Link
// cannot wrap them and the visit has to be wired by hand. shouldIntercept is
// the same predicate Inertia's own link action uses: a plain left click is
// taken over, ctrl-click and middle click still open a new tab.
export function visitOnClick(href: string) {
  return (event: MouseEvent) => {
    if (!shouldIntercept(event)) return

    event.preventDefault()
    router.visit(href)
  }
}
