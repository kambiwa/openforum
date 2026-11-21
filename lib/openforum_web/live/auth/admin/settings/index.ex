defmodule OpenforumWeb.Auth.Admin.Settings.Index do
  use OpenforumWeb, :live_view

  alias Openforum.Context.Dashboard

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "System Settings")
      |> assign(:current_page, :settings)
      |> assign(:system_health, Dashboard.system_health())
      |> assign(:system_time, DateTime.utc_now())
      |> assign(:settings_sections, settings_sections())

    if connected?(socket) do
      Process.send_after(self(), :settings_clock_tick, 1_000)
      Process.send_after(self(), :settings_health_tick, 30_000)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:settings_clock_tick, socket) do
    Process.send_after(self(), :settings_clock_tick, 1_000)
    {:noreply, assign(socket, :system_time, DateTime.utc_now())}
  end

  def handle_info(:settings_health_tick, socket) do
    Process.send_after(self(), :settings_health_tick, 30_000)
    {:noreply, assign(socket, :system_health, Dashboard.system_health())}
  end

  @impl true
  def handle_event("refresh_health", _params, socket) do
    {:noreply,
     socket
     |> assign(:system_health, Dashboard.system_health())
     |> put_flash(:info, "System checks refreshed.")}
  end

  defp settings_sections do
    [
      %{
        title: "Content & workflow",
        description: "Manage the review process and published resources.",
        icon: "hero-document-check",
        links: [
          %{
            label: "Approval workflows",
            href: "/admin/work_flows",
            icon: "hero-arrows-right-left"
          },
          %{label: "Review queue", href: "/admin/approval-queue", icon: "hero-clock"},
          %{label: "Media library", href: "/admin/media", icon: "hero-photo"}
        ]
      },
      %{
        title: "People & access",
        description: "Control account access and review assigned roles.",
        icon: "hero-shield-check",
        links: [
          %{label: "Manage users", href: "/admin/users", icon: "hero-users"},
          %{label: "Roles & permissions", href: "/admin/roles", icon: "hero-lock-closed"},
          %{label: "Your profile", href: "/admin/profile", icon: "hero-user-circle"}
        ]
      }
    ]
  end

  defp status_label(:healthy), do: "Operational"
  defp status_label(_), do: "Needs attention"

  defp status_dot(:healthy), do: "bg-emerald-500"
  defp status_dot(_), do: "bg-rose-500"

  defp format_uptime(seconds) do
    days = div(seconds, 86_400)
    hours = div(rem(seconds, 86_400), 3_600)
    minutes = div(rem(seconds, 3_600), 60)

    cond do
      days > 0 -> "#{days} days, #{hours} hours"
      hours > 0 -> "#{hours} hours, #{minutes} minutes"
      true -> "#{minutes} minutes"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin_app flash={@flash} current_scope={@current_scope} current_page={@current_page}>
      <main class="min-h-full bg-[#F3F6F8] p-5 lg:p-8">
        <div class="mx-auto flex max-w-[1500px] flex-col gap-7">
          <header class="flex flex-col justify-between gap-5 border-b border-[#D7E1E7] pb-6 md:flex-row md:items-end">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.2em] text-[#1769AA]">System</p>
              <h1 class="mt-2 text-3xl font-semibold tracking-[-0.04em] text-[#0B2E4F] sm:text-4xl">
                Settings & health
              </h1>
              <p class="mt-2 max-w-2xl text-sm leading-6 text-[#64748B]">
                Review platform status and jump to the controls for content, workflows, and access.
              </p>
            </div>
            <button
              id="refresh-system-health"
              type="button"
              phx-click="refresh_health"
              class="inline-flex min-h-11 items-center justify-center gap-2 bg-[#0B2E4F] px-5 text-sm font-semibold text-white transition-colors hover:bg-[#1769AA]"
            >
              <.icon name="hero-arrow-path" class="size-4" /> Refresh checks
            </button>
          </header>

          <section class="grid gap-5 xl:grid-cols-[1.15fr_0.85fr]" aria-label="System health overview">
            <article class="overflow-hidden border border-[#DCE5EA] bg-white">
              <div class="flex flex-wrap items-start justify-between gap-4 bg-[#0B2E4F] px-6 py-6 sm:px-8">
                <div>
                  <p class="text-xs font-semibold uppercase tracking-[0.18em] text-[#D8B746]">
                    Live status
                  </p>
                  <h2 class="mt-2 text-2xl font-semibold tracking-tight text-white">
                    Platform services
                  </h2>
                  <p class="mt-2 text-sm text-white/65">
                    Health checks refresh automatically every 30 seconds.
                  </p>
                </div>
                <div class="border border-white/15 bg-white/5 px-4 py-3 text-right">
                  <p class="text-[10px] font-semibold uppercase tracking-[0.16em] text-white/60">
                    Server clock · UTC
                  </p>
                  <p
                    id="settings-system-time"
                    class="mt-1 font-mono text-xl font-semibold tabular-nums text-white"
                  >
                    {Calendar.strftime(@system_time, "%H:%M:%S")}
                  </p>
                  <p class="text-xs text-white/60">{Calendar.strftime(@system_time, "%d %B %Y")}</p>
                </div>
              </div>

              <div class="grid divide-y divide-[#E8EDF0] sm:grid-cols-2 sm:divide-x sm:divide-y-0">
                <div class="flex items-center gap-4 px-6 py-5 sm:px-8">
                  <span class={["size-3 shrink-0", status_dot(@system_health.database)]}></span>
                  <div class="min-w-0 flex-1">
                    <p class="text-xs font-medium uppercase tracking-wide text-[#718096]">
                      Database connection
                    </p>
                    <p class="mt-1 text-base font-semibold text-[#0B2E4F]">
                      {status_label(@system_health.database)}
                    </p>
                  </div>
                  <.icon name="hero-circle-stack" class="size-5 text-[#1769AA]" />
                </div>
                <div class="flex items-center gap-4 px-6 py-5 sm:px-8">
                  <span class={["size-3 shrink-0", status_dot(@system_health.storage)]}></span>
                  <div class="min-w-0 flex-1">
                    <p class="text-xs font-medium uppercase tracking-wide text-[#718096]">
                      Upload storage
                    </p>
                    <p class="mt-1 text-base font-semibold text-[#0B2E4F]">
                      {status_label(@system_health.storage)}
                    </p>
                  </div>
                  <.icon name="hero-server-stack" class="size-5 text-[#1769AA]" />
                </div>
              </div>
            </article>

            <article class="grid grid-cols-2 border border-[#DCE5EA] bg-white">
              <div class="border-b border-r border-[#E8EDF0] p-5 sm:p-6">
                <span class="flex size-9 items-center justify-center bg-[#EAF3F8] text-[#1769AA]"><.icon
                  name="hero-arrow-path-rounded-square"
                  class="size-4"
                /></span>
                <p class="mt-5 text-xs font-medium uppercase tracking-wide text-[#718096]">
                  Server uptime
                </p>
                <p class="mt-1 text-lg font-semibold text-[#0B2E4F]">
                  {format_uptime(@system_health.uptime_seconds)}
                </p>
              </div>
              <div class="border-b border-[#E8EDF0] p-5 sm:p-6">
                <span class="flex size-9 items-center justify-center bg-[#FBF5DF] text-[#A98618]"><.icon
                  name="hero-cpu-chip"
                  class="size-4"
                /></span>
                <p class="mt-5 text-xs font-medium uppercase tracking-wide text-[#718096]">
                  Runtime memory
                </p>
                <p class="mt-1 text-lg font-semibold text-[#0B2E4F]">{@system_health.memory_mb} MB</p>
              </div>
              <div class="col-span-2 flex items-center justify-between gap-4 px-5 py-4 sm:px-6">
                <div>
                  <p class="text-xs font-medium uppercase tracking-wide text-[#718096]">
                    Last health check
                  </p>
                  <p class="mt-1 text-sm font-semibold text-[#0B2E4F]">
                    {Calendar.strftime(@system_health.checked_at, "%d %b %Y · %H:%M:%S UTC")}
                  </p>
                </div>
                <span class="flex size-9 items-center justify-center border border-[#DCE5EA] text-[#1769AA]"><.icon
                  name="hero-shield-check"
                  class="size-4"
                /></span>
              </div>
            </article>
          </section>

          <section aria-labelledby="configuration-heading">
            <div class="mb-4">
              <p class="text-xs font-semibold uppercase tracking-[0.18em] text-[#1769AA]">
                Current configuration
              </p>
              <h2 id="configuration-heading" class="mt-1 text-xl font-semibold text-[#0B2E4F]">
                Platform defaults
              </h2>
            </div>
            <div class="grid gap-px border border-[#DCE5EA] bg-[#DCE5EA] sm:grid-cols-2 xl:grid-cols-4">
              <div class="bg-white p-5">
                <.icon name="hero-globe-alt" class="size-5 text-[#1769AA]" />
                <p class="mt-4 text-xs font-medium uppercase tracking-wide text-[#718096]">
                  Public library
                </p>
                <.link
                  navigate={~p"/media"}
                  class="mt-1 inline-flex items-center gap-1 text-sm font-semibold text-[#0B2E4F] hover:text-[#1769AA]"
                >/media <.icon name="hero-arrow-up-right" class="size-3.5" /></.link>
              </div>
              <div class="bg-white p-5">
                <.icon name="hero-cloud-arrow-up" class="size-5 text-[#1769AA]" />
                <p class="mt-4 text-xs font-medium uppercase tracking-wide text-[#718096]">
                  Maximum media upload
                </p>
                <p class="mt-1 text-sm font-semibold text-[#0B2E4F]">100 MB per file</p>
              </div>
              <div class="bg-white p-5">
                <.icon name="hero-clock" class="size-5 text-[#1769AA]" />
                <p class="mt-4 text-xs font-medium uppercase tracking-wide text-[#718096]">
                  System timezone
                </p>
                <p class="mt-1 text-sm font-semibold text-[#0B2E4F]">UTC</p>
              </div>
              <div class="bg-white p-5">
                <.icon name="hero-document-check" class="size-5 text-[#1769AA]" />
                <p class="mt-4 text-xs font-medium uppercase tracking-wide text-[#718096]">
                  Publishing
                </p>
                <p class="mt-1 text-sm font-semibold text-[#0B2E4F]">Manual review workflow</p>
              </div>
            </div>
          </section>

          <section aria-label="Administration shortcuts">
            <div class="mb-4">
              <p class="text-xs font-semibold uppercase tracking-[0.18em] text-[#1769AA]">
                Administration
              </p>
              <h2 class="mt-1 text-xl font-semibold text-[#0B2E4F]">Manage platform areas</h2>
            </div>
            <div class="grid gap-5 xl:grid-cols-2">
              <article
                :for={section <- @settings_sections}
                class="border border-[#DCE5EA] bg-white p-5 sm:p-6"
              >
                <div class="flex items-start gap-4">
                  <span class="flex size-11 shrink-0 items-center justify-center bg-[#0B2E4F] text-[#D8B746]"><.icon
                    name={section.icon}
                    class="size-5"
                  /></span>
                  <div>
                    <h3 class="text-base font-semibold text-[#0B2E4F]">{section.title}</h3>
                    <p class="mt-1 text-sm leading-6 text-[#64748B]">{section.description}</p>
                  </div>
                </div>
                <div class="mt-5 grid gap-2 sm:grid-cols-3">
                  <.link
                    :for={link <- section.links}
                    navigate={link.href}
                    class="group flex items-center gap-2 border border-[#E5EBEF] px-3 py-3 text-sm font-medium text-[#31485A] transition-colors hover:border-[#9AB8CB] hover:bg-[#F4F8FB] hover:text-[#0B2E4F]"
                  >
                    <.icon name={link.icon} class="size-4 shrink-0 text-[#1769AA]" />
                    <span>{link.label}</span>
                    <.icon
                      name="hero-arrow-right"
                      class="ml-auto size-3.5 text-[#9AA9B5] transition-transform group-hover:translate-x-0.5"
                    />
                  </.link>
                </div>
              </article>
            </div>
          </section>
        </div>
      </main>
    </Layouts.admin_app>
    """
  end
end
