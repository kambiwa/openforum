defmodule OpenforumWeb.Layouts do
  @moduledoc """
  Layouts and shared UI components for OpenForum,
  a New Apostolic Church doctrine and knowledge learning platform.
  """

  use OpenforumWeb, :html

  embed_templates "layouts/*"

  # ───────────────────────────────────────────────
  #  PUBLIC LAYOUT
  # ───────────────────────────────────────────────

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  attr :mobile_menu_open, :boolean, default: false
  attr :current_page, :atom, default: nil
  attr :show_footer, :boolean, default: true
  slot :inner_block, required: true

  def unauth_app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col bg-[#FAFAF7] text-[#252525]">

      <%!-- PUBLIC NAVIGATION --%>
      <header class="fixed top-0 inset-x-0 z-50 bg-white/95 backdrop-blur-md border-b border-[#E5E7EB]">
        <nav class="mx-auto max-w-7xl px-5 sm:px-6 lg:px-8 h-20 flex items-center justify-between">

          <%!-- BRAND --%>
          <a href={~p"/"} class="flex items-center gap-3 shrink-0">
            <span class="w-10 h-10 rounded-lg bg-[#0B2E4F] text-white flex items-center justify-center shadow-sm">
              <.icon name="hero-book-open" class="size-5" />
            </span>

            <span class="flex flex-col">
              <span class="text-lg font-bold tracking-tight text-[#0B2E4F]">
                OpenForum
              </span>

              <span class="hidden sm:block text-[0.65rem] tracking-wide text-[#6B7280]">
                New Apostolic Church Learning Platform
              </span>
            </span>
          </a>

          <%!-- DESKTOP NAVIGATION --%>
          <ul class="hidden xl:flex items-center gap-5">
            <li>
              <.nav_link
                href={~p"/"}
                label="Home"
                active={@current_page == :home}
              />
            </li>

            <li>
              <.nav_link
                href={~p"/learn"}
                label="Learn"
                active={@current_page == :learn}
              />
            </li>

            <li>
              <.nav_link
                href={~p"/bible"}
                label="Bible"
                active={@current_page == :bible}
              />
            </li>

            <li>
              <.nav_link
                href={~p"/doctrine"}
                label="Doctrine"
                active={@current_page == :doctrine}
              />
            </li>

            <li>
              <.nav_link
                href={~p"/catechism"}
                label="Catechism"
                active={@current_page == :catechism}
              />
            </li>

            <li>
              <.nav_link
                href={~p"/questions-and-answers"}
                label="Q&A"
                active={@current_page == :questions_and_answers}
              />
            </li>

            <li>
              <.nav_link
                href={~p"/media"}
                label="Media"
                active={@current_page == :media}
              />
            </li>
          </ul>

          <%!-- DESKTOP ACTIONS --%>
          <div class="hidden xl:flex items-center gap-2">
            <a
              href={~p"/search"}
              aria-label="Search OpenForum"
              class="w-10 h-10 rounded-lg flex items-center justify-center text-[#0B2E4F] hover:bg-[#EAF3F8] transition-colors"
            >
              <.icon name="hero-magnifying-glass" class="size-5" />
            </a>

            <a
              href={~p"/users/log-in"}
              class="px-3 py-2 text-sm font-medium text-[#0B2E4F] hover:text-[#1769AA] transition-colors"
            >
              Sign In
            </a>

            <a
              href={~p"/users/register"}
              class="px-4 py-2.5 rounded-md bg-[#0B2E4F] text-white text-sm font-semibold hover:bg-[#1769AA] transition-colors shadow-sm"
            >
              Join OpenForum
            </a>
          </div>

          <%!-- MOBILE MENU BUTTON --%>
          <button
            aria-label="Toggle navigation menu"
            phx-click="toggle_mobile_menu"
            class="xl:hidden w-10 h-10 rounded-lg flex items-center justify-center text-[#0B2E4F] hover:bg-[#EAF3F8] transition-colors"
          >
            <.icon name="hero-bars-3" class="size-6" />
          </button>
        </nav>

        <%!-- MOBILE NAVIGATION --%>
        <div
          :if={@mobile_menu_open}
          class="xl:hidden mx-4 mb-4 p-5 bg-white border border-[#E5E7EB] rounded-xl shadow-lg"
        >
          <div class="flex flex-col gap-1">
            <.nav_link
              href={~p"/"}
              label="Home"
              active={@current_page == :home}
            />

            <.nav_link
              href={~p"/learn"}
              label="Learn"
              active={@current_page == :learn}
            />

            <.nav_link
              href={~p"/bible"}
              label="Bible"
              active={@current_page == :bible}
            />

            <.nav_link
              href={~p"/doctrine"}
              label="Doctrine"
              active={@current_page == :doctrine}
            />

            <.nav_link
              href={~p"/catechism"}
              label="Catechism"
              active={@current_page == :catechism}
            />

            <.nav_link
              href={~p"/questions-and-answers"}
              label="Questions & Answers"
              active={@current_page == :questions_and_answers}
            />

            <.nav_link
              href={~p"/media"}
              label="Audio & Video"
              active={@current_page == :media}
            />

            <div class="border-t border-[#E5E7EB] my-3"></div>

            <a
              href={~p"/users/log-in"}
              class="px-3 py-2.5 text-sm font-medium text-[#0B2E4F]"
            >
              Sign In
            </a>

            <a
              href={~p"/users/register"}
              class="mt-2 px-4 py-3 rounded-md bg-[#0B2E4F] text-white text-sm font-semibold text-center"
            >
              Join OpenForum
            </a>
          </div>
        </div>
      </header>

      <%!-- MAIN CONTENT --%>
      <main class="flex-1 pt-20">
        <.flash_group flash={@flash} />
        {render_slot(@inner_block)}
      </main>

      <%!-- FOOTER --%>
      <.openforum_footer :if={@show_footer} />
    </div>
    """
  end

  # ───────────────────────────────────────────────
  #  ADMIN LAYOUT
  # ───────────────────────────────────────────────

  attr :flash, :map, required: true
  attr :page_title, :string, default: "Dashboard"
  attr :current_page, :atom, default: :dashboard
  attr :current_scope, :map, default: nil
  slot :inner_block, required: true

  def admin_app(assigns) do
    ~H"""
    <div class="drawer lg:drawer-open min-h-screen bg-[#F7F9FB]">
      <input id="admin-sidebar" type="checkbox" class="drawer-toggle" />

      <%!-- MAIN CONTENT AREA --%>
      <div class="drawer-content flex flex-col min-w-0">

        <%!-- TOP BAR --%>
        <header class="sticky top-0 z-30 h-16 px-4 sm:px-6 bg-white border-b border-[#E5E7EB] shadow-sm flex items-center">

          <label
            for="admin-sidebar"
            class="lg:hidden w-9 h-9 mr-3 rounded-lg border border-[#E5E7EB] text-[#0B2E4F] flex items-center justify-center cursor-pointer hover:bg-[#EAF3F8] transition-colors"
            aria-label="Open sidebar"
          >
            <.icon name="hero-bars-3" class="size-5" />
          </label>

          <%!-- PAGE TITLE --%>
          <div class="flex-1 min-w-0">
            <h1 class="text-sm sm:text-base font-semibold text-[#0B2E4F] truncate">
              {@page_title}
            </h1>
          </div>

          <%!-- TOP ACTIONS --%>
          <div class="flex items-center gap-2">

            <button
              aria-label="Notifications"
              class="relative w-9 h-9 rounded-lg text-[#6B7280] flex items-center justify-center hover:bg-[#EAF3F8] hover:text-[#1769AA] transition-colors"
            >
              <.icon name="hero-bell" class="size-5" />
            </button>

            <div class="w-px h-6 bg-[#E5E7EB] mx-1"></div>

            <%!-- USER DROPDOWN --%>
            <div class="dropdown dropdown-end">
              <label
                tabindex="0"
                class="flex items-center gap-2 cursor-pointer px-2 py-1.5 rounded-lg hover:bg-[#F4F8FB] transition-colors"
              >
                <div class="w-8 h-8 rounded-full bg-[#0B2E4F] text-white flex items-center justify-center text-xs font-bold">
                  A
                </div>

                <div class="hidden sm:block text-left">
                  <p class="text-xs font-semibold text-[#252525]">
                    Administrator
                  </p>

                  <p class="text-[0.68rem] text-[#6B7280]">
                    OpenForum Admin
                  </p>
                </div>

                <.icon
                  name="hero-chevron-down"
                  class="size-3.5 hidden sm:block text-[#9CA3AF]"
                />
              </label>

              <ul
                tabindex="0"
                class="dropdown-content z-50 mt-2 w-60 bg-white rounded-xl shadow-lg border border-[#E5E7EB] p-1.5 text-sm"
              >
                <li class="px-3 py-3 border-b border-[#E5E7EB] mb-1">
                  <p class="font-semibold text-[#252525] text-sm">
                    Administrator
                  </p>

                  <p class="text-[#6B7280] text-xs mt-1">
                    OpenForum Administration
                  </p>
                </li>

                <.admin_menu_item
                  href={~p"/admin/profile"}
                  icon="hero-user-circle"
                  label="My Profile"
                />

                <.admin_menu_item
                  href={~p"/admin/settings"}
                  icon="hero-cog-6-tooth"
                  label="Settings"
                />

                <li class="border-t border-[#E5E7EB] mt-1 pt-1">
                  <.link
                    href={~p"/users/log-out"}
                    method="delete"
                    class="flex items-center gap-2 px-3 py-2 rounded-lg text-red-600 hover:bg-red-50 transition-colors"
                  >
                    <.icon name="hero-arrow-right-on-rectangle" class="size-4" />
                    Log out
                  </.link>
                </li>
              </ul>
            </div>
          </div>
        </header>

        <%!-- PAGE CONTENT --%>
        <main class="flex-1 bg-[#F7F9FB]">
          <.flash_group flash={@flash} />
          {render_slot(@inner_block)}
        </main>
      </div>

      <%!-- ADMIN SIDEBAR --%>
      <div class="drawer-side z-40">
        <label
          for="admin-sidebar"
          aria-label="Close sidebar"
          class="drawer-overlay"
        >
        </label>

        <aside class="min-h-full w-72 bg-white border-r border-[#E5E7EB] flex flex-col">

          <%!-- ADMIN BRAND --%>
          <div class="h-16 px-5 flex items-center gap-3 border-b border-[#E5E7EB] shrink-0">
            <div class="w-9 h-9 rounded-lg bg-[#0B2E4F] text-white flex items-center justify-center">
              <.icon name="hero-book-open" class="size-5" />
            </div>

            <div>
              <p class="font-bold text-sm tracking-tight text-[#0B2E4F]">
                OpenForum
              </p>

              <p class="text-[0.65rem] uppercase tracking-wider text-[#6B7280]">
                Administration
              </p>
            </div>
          </div>

          <%!-- SIDEBAR NAVIGATION --%>
          <nav class="flex-1 px-3 py-5 overflow-y-auto">

            <.sidebar_group label="Overview" />

            <.sidebar_link
              href={~p"/admin/dashboard"}
              icon="hero-squares-2x2"
              label="Dashboard"
              active={@current_page == :dashboard}
            />

            <%!-- CONTENT --%>
            <.sidebar_group label="Content" />

            <.sidebar_link
              href={~p"/admin/content"}
              icon="hero-document-text"
              label="All Content"
              active={@current_page == :content}
            />

            <.sidebar_link
              href={~p"/admin/drafts"}
              icon="hero-pencil-square"
              label="Drafts"
              active={@current_page == :drafts}
            />

            <.sidebar_link
              href={~p"/admin/approval-queue"}
              icon="hero-clock"
              label="Pending Approval"
              active={@current_page == :approval_queue}
            />

            <.sidebar_link
              href={~p"/admin/published"}
              icon="hero-globe-alt"
              label="Published"
              active={@current_page == :published}
            />

            <.sidebar_link
              href={~p"/admin/media"}
              icon="hero-photo"
              label="Media Library"
              active={@current_page == :media}
            />

            <%!-- KNOWLEDGE --%>
            <.sidebar_group label="Knowledge" />

            <.sidebar_link
              href={~p"/admin/bible"}
              icon="hero-book-open"
              label="Bible"
              active={@current_page == :bible}
            />

            <.sidebar_link
              href={~p"/admin/doctrine"}
              icon="hero-academic-cap"
              label="Doctrine"
              active={@current_page == :doctrine}
            />

            <.sidebar_link
              href={~p"/admin/catechism"}
              icon="hero-bookmark-square"
              label="Catechism"
              active={@current_page == :catechism}
            />

            <.sidebar_link
              href={~p"/admin/questions-and-answers"}
              icon="hero-question-mark-circle"
              label="Questions & Answers"
              active={@current_page == :questions_and_answers}
            />

            <.sidebar_link
              href={~p"/admin/learning-paths"}
              icon="hero-map"
              label="Learning Paths"
              active={@current_page == :learning_paths}
            />

            <%!-- WORKFLOW --%>
            <.sidebar_group label="Workflow" />

            <.sidebar_link
              href={~p"/admin/workflows"}
              icon="hero-arrows-right-left"
              label="Approval Workflows"
              active={@current_page == :workflows}
            />

            <.sidebar_link
              href={~p"/admin/reviews"}
              icon="hero-check-badge"
              label="Review History"
              active={@current_page == :reviews}
            />

            <.sidebar_link
              href={~p"/admin/audit-logs"}
              icon="hero-clipboard-document-list"
              label="Audit Trail"
              active={@current_page == :audit_logs}
            />

            <%!-- ORGANISATION --%>
            <.sidebar_group label="Organisation" />

            <.sidebar_link
              href={~p"/admin/organisational-units"}
              icon="hero-building-office-2"
              label="Organisational Units"
              active={@current_page == :organisational_units}
            />

            <.sidebar_link
              href={~p"/admin/congregations"}
              icon="hero-home-modern"
              label="Congregations"
              active={@current_page == :congregations}
            />

            <.sidebar_link
              href={~p"/admin/district-rector-areas"}
              icon="hero-building-library"
              label="District Rector Areas"
              active={@current_page == :district_rector_areas}
            />

            <.sidebar_link
              href={~p"/admin/apostle-areas"}
              icon="hero-map-pin"
              label="Apostle Areas"
              active={@current_page == :apostle_areas}
            />

            <.sidebar_link
              href={~p"/admin/lead-apostle-areas"}
              icon="hero-map"
              label="Lead Apostle Areas"
              active={@current_page == :lead_apostle_areas}
            />

            <.sidebar_link
              href={~p"/admin/district-apostle-areas"}
              icon="hero-globe-europe-africa"
              label="District Apostle Areas"
              active={@current_page == :district_apostle_areas}
            />

            <%!-- ACCESS MANAGEMENT --%>
            <.sidebar_group label="Access" />

            <.sidebar_link
              href={~p"/admin/users"}
              icon="hero-users"
              label="Users"
              active={@current_page == :users}
            />

            <.sidebar_link
              href={~p"/admin/roles"}
              icon="hero-shield-check"
              label="Roles & Permissions"
              active={@current_page == :roles}
            />

            <%!-- SYSTEM --%>
            <.sidebar_group label="System" />

            <.sidebar_link
              href={~p"/admin/settings"}
              icon="hero-cog-6-tooth"
              label="Settings"
              active={@current_page == :settings}
            />
          </nav>

          <%!-- SIDEBAR FOOTER --%>
          <div class="p-3 border-t border-[#E5E7EB] shrink-0">
            <.link
              href={~p"/users/log-out"}
              method="delete"
              class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-[#6B7280] hover:bg-red-50 hover:text-red-600 transition-colors"
            >
              <.icon name="hero-arrow-right-on-rectangle" class="size-4" />
              <span>Log out</span>
            </.link>

            <p class="text-[0.65rem] text-[#9CA3AF] mt-3 px-3">
              © {Date.utc_today().year} OpenForum
            </p>
          </div>
        </aside>
      </div>
    </div>
    """
  end

  # ───────────────────────────────────────────────
  #  DEFAULT PHOENIX LAYOUT
  # ───────────────────────────────────────────────

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href="/" class="flex w-fit items-center gap-2">
          <span class="w-9 h-9 rounded-lg bg-[#0B2E4F] text-white flex items-center justify-center">
            <.icon name="hero-book-open" class="size-5" />
          </span>

          <span class="text-sm font-semibold text-[#0B2E4F]">
            OpenForum
          </span>
        </a>
      </div>

      <div class="flex-none">
        <ul class="flex px-1 space-x-4 items-center">
          <li>
            <a href={~p"/"} class="btn btn-ghost">
              Home
            </a>
          </li>

          <li>
            <.theme_toggle />
          </li>
        </ul>
      </div>
    </header>

    <main>
      <div>
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  # ───────────────────────────────────────────────
  #  OPENFORUM FOOTER
  # ───────────────────────────────────────────────

  defp openforum_footer(assigns) do
    ~H"""
    <footer class="bg-[#0B2E4F] text-white">
      <div class="mx-auto max-w-7xl px-6 lg:px-8 py-14">

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-10">

          <%!-- BRAND --%>
          <div class="lg:col-span-2">
            <div class="flex items-center gap-3">
              <span class="w-10 h-10 rounded-lg bg-white/10 flex items-center justify-center">
                <.icon
                  name="hero-book-open"
                  class="size-5 text-[#C9A227]"
                />
              </span>

              <div>
                <p class="font-bold text-lg">
                  OpenForum
                </p>

                <p class="text-xs text-white/60">
                  New Apostolic Church Learning Platform
                </p>
              </div>
            </div>

            <p class="mt-5 max-w-md text-sm leading-6 text-white/70">
              A digital learning platform supporting faith, doctrine,
              knowledge, and spiritual growth through trusted and
              approved learning resources.
            </p>
          </div>

          <%!-- EXPLORE --%>
          <div>
            <h3 class="text-sm font-semibold text-[#C9A227]">
              Explore
            </h3>

            <ul class="mt-4 space-y-3 text-sm text-white/70">
              <li>
                <a href={~p"/bible"} class="hover:text-white transition-colors">
                  Bible
                </a>
              </li>

              <li>
                <a href={~p"/doctrine"} class="hover:text-white transition-colors">
                  Doctrine
                </a>
              </li>

              <li>
                <a href={~p"/catechism"} class="hover:text-white transition-colors">
                  Catechism
                </a>
              </li>

              <li>
                <a href={~p"/questions-and-answers"} class="hover:text-white transition-colors">
                  Questions & Answers
                </a>
              </li>
            </ul>
          </div>

          <%!-- LEARN --%>
          <div>
            <h3 class="text-sm font-semibold text-[#C9A227]">
              Learn
            </h3>

            <ul class="mt-4 space-y-3 text-sm text-white/70">
              <li>
                <a href={~p"/learn"} class="hover:text-white transition-colors">
                  Learning Library
                </a>
              </li>

              <li>
                <a href={~p"/audio"} class="hover:text-white transition-colors">
                  Audio
                </a>
              </li>

              <li>
                <a href={~p"/video"} class="hover:text-white transition-colors">
                  Video
                </a>
              </li>

              <li>
                <a href={~p"/latest"} class="hover:text-white transition-colors">
                  Latest Content
                </a>
              </li>
            </ul>
          </div>

          <%!-- PLATFORM --%>
          <div>
            <h3 class="text-sm font-semibold text-[#C9A227]">
              Platform
            </h3>

            <ul class="mt-4 space-y-3 text-sm text-white/70">
              <li>
                <a href={~p"/about"} class="hover:text-white transition-colors">
                  About OpenForum
                </a>
              </li>

              <li>
                <a href={~p"/help"} class="hover:text-white transition-colors">
                  Help & Support
                </a>
              </li>

              <li>
                <a href={~p"/privacy"} class="hover:text-white transition-colors">
                  Privacy
                </a>
              </li>

              <li>
                <a href={~p"/terms"} class="hover:text-white transition-colors">
                  Terms of Use
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div class="mt-12 pt-6 border-t border-white/10 flex flex-col sm:flex-row justify-between gap-3">
          <p class="text-xs text-white/50">
            © {Date.utc_today().year} OpenForum. All rights reserved.
          </p>

          <p class="text-xs text-white/50">
            Learn. Understand. Grow in Faith.
          </p>
        </div>
      </div>
    </footer>
    """
  end

  # ───────────────────────────────────────────────
  #  FLASH GROUP
  # ───────────────────────────────────────────────

  attr :flash, :map, required: true
  attr :id, :string, default: "flash-group"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden")
        }
        phx-connected={
          hide(".phx-client-error #client-error")
          |> JS.set_attribute({"hidden", ""})
        }
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon
          name="hero-arrow-path"
          class="ml-1 size-3 motion-safe:animate-spin"
        />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden")
        }
        phx-connected={
          hide(".phx-server-error #server-error")
          |> JS.set_attribute({"hidden", ""})
        }
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon
          name="hero-arrow-path"
          class="ml-1 size-3 motion-safe:animate-spin"
        />
      </.flash>
    </div>
    """
  end

  # ───────────────────────────────────────────────
  #  THEME TOGGLE
  # ───────────────────────────────────────────────

  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon
          name="hero-computer-desktop-micro"
          class="size-4 opacity-75 hover:opacity-100"
        />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon
          name="hero-sun-micro"
          class="size-4 opacity-75 hover:opacity-100"
        />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon
          name="hero-moon-micro"
          class="size-4 opacity-75 hover:opacity-100"
        />
      </button>
    </div>
    """
  end

  # ───────────────────────────────────────────────
  #  PUBLIC NAVIGATION COMPONENTS
  # ───────────────────────────────────────────────

  attr :href, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false

  defp nav_link(assigns) do
    ~H"""
    <a
      href={@href}
      class={[
        "block px-2 py-2 text-sm font-medium transition-colors whitespace-nowrap rounded-md",
        if(
          @active,
          do: "text-[#1769AA] bg-[#EAF3F8]/60",
          else: "text-[#374151] hover:text-[#1769AA] hover:bg-[#EAF3F8]/50"
        )
      ]}
    >
      {@label}
    </a>
    """
  end

  # ───────────────────────────────────────────────
  #  ADMIN SIDEBAR COMPONENTS
  # ───────────────────────────────────────────────

  attr :label, :string, required: true

  defp sidebar_group(assigns) do
    ~H"""
    <p class="text-[0.62rem] font-bold tracking-[0.18em] uppercase text-[#6B7280] px-3 mt-6 mb-2">
      {@label}
    </p>
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false

  defp sidebar_link(assigns) do
    ~H"""
    <a
      href={@href}
      class={[
        "flex items-center gap-3 px-3 py-2.5 rounded-lg text-[0.82rem] border-l-[3px] transition-colors mb-1",
        if(
          @active,
          do:
            "font-semibold text-[#0B2E4F] bg-[#EAF3F8] border-[#1769AA]",
          else:
            "font-medium text-[#4B5563] border-transparent hover:bg-[#F4F8FB] hover:text-[#1769AA]"
        )
      ]}
    >
      <.icon
        name={@icon}
        class="size-4 shrink-0"
      />

      <span class="truncate">
        {@label}
      </span>
    </a>
    """
  end

  # ───────────────────────────────────────────────
  #  ADMIN DROPDOWN ITEM
  # ───────────────────────────────────────────────

  attr :href, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true

  defp admin_menu_item(assigns) do
    ~H"""
    <li>
      <a
        href={@href}
        class="flex items-center gap-2 px-3 py-2 rounded-lg text-sm text-[#4B5563] hover:bg-[#EAF3F8] hover:text-[#1769AA] transition-colors"
      >
        <.icon name={@icon} class="size-4" />
        {@label}
      </a>
    </li>
    """
  end
end
