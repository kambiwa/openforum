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
              <.nav_link href={~p"/"} label="Home" active={@current_page == :home} />
            </li>

            <li>
              <.nav_link
                href={~p"/publications"}
                label="Publications"
                active={@current_page == :publications}
              />
            </li>

            <li>
              <.nav_link href={~p"/learn"} label="Learn" active={@current_page == :learn} />
            </li>

            <li>
              <.nav_link href={~p"/bible"} label="Bible" active={@current_page == :bible} />
            </li>

            <li>
              <.nav_link href={~p"/catechism"} label="Catechism" active={@current_page == :catechism} />
            </li>

            <li>
              <.nav_link
                href={~p"/questions-and-answers"}
                label="Q&A"
                active={@current_page == :questions_and_answers}
              />
            </li>

            <li>
              <.nav_link href={~p"/media"} label="Media" active={@current_page == :media} />
            </li>
          </ul>

          <%!-- DESKTOP ACTIONS --%>
          <div class="hidden xl:flex items-center gap-2">
            <.theme_toggle id="public-theme-toggle-desktop" />

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
          <div class="flex items-center gap-2 xl:hidden">
            <.theme_toggle id="public-theme-toggle-mobile" />
            <button
              aria-label="Toggle navigation menu"
              phx-click="toggle_mobile_menu"
              class="flex size-10 items-center justify-center text-[#0B2E4F] transition-colors hover:bg-[#EAF3F8]"
            >
              <.icon name="hero-bars-3" class="size-6" />
            </button>
          </div>
        </nav>

        <%!-- MOBILE NAVIGATION --%>
        <div
          :if={@mobile_menu_open}
          class="xl:hidden mx-4 mb-4 p-5 bg-white border border-[#E5E7EB] rounded-xl shadow-lg"
        >
          <div class="flex flex-col gap-1">
            <.nav_link href={~p"/"} label="Home" active={@current_page == :home} />

            <.nav_link
              href={~p"/publications"}
              label="Publications"
              active={@current_page == :publications}
            />

            <.nav_link href={~p"/bible"} label="Bible" active={@current_page == :bible} />

            <.nav_link href={~p"/doctrine"} label="Doctrine" active={@current_page == :doctrine} />

            <.nav_link href={~p"/catechism"} label="Catechism" active={@current_page == :catechism} />

            <.nav_link
              href={~p"/questions-and-answers"}
              label="Questions & Answers"
              active={@current_page == :questions_and_answers}
            />

            <.nav_link href={~p"/media"} label="Audio & Video" active={@current_page == :media} />

            <div class="border-t border-[#E5E7EB] my-3"></div>

            <a href={~p"/users/log-in"} class="px-3 py-2.5 text-sm font-medium text-[#0B2E4F]">
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
    <div class="drawer admin-shell lg:drawer-open min-h-screen bg-[#F7F9FB]">
      <input id="admin-sidebar" type="checkbox" class="drawer-toggle" />
      <input
        id="admin-sidebar-collapse"
        type="checkbox"
        class="sr-only"
        phx-hook=".AdminSidebarCollapse"
        aria-label="Collapse admin sidebar"
      />

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
            <.theme_toggle id="admin-theme-toggle" />

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
                <.user_avatar user={@current_scope.user} />

                <div class="block min-w-0 max-w-24 text-left sm:max-w-40">
                  <p class="truncate text-xs font-semibold text-[#252525]">
                    {@current_scope.user.first_name} {@current_scope.user.last_name}
                  </p>

                  <p class="truncate text-[0.68rem] text-[#6B7280]">
                    {role_label(@current_scope.user.roles)}
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
                <li class="px-3 py-3 border-b border-[#E5E7EB] mb-1 flex items-center gap-3">
                  <.user_avatar user={@current_scope.user} size="w-10 h-10 text-sm" />

                  <div>
                    <p class="font-semibold text-[#252525] text-sm">
                      {@current_scope.user.first_name} {@current_scope.user.last_name}
                    </p>

                    <p class="text-[#6B7280] text-xs mt-1">
                      {role_label(@current_scope.user.roles)}
                    </p>
                  </div>
                </li>

                <.admin_menu_item
                  href={~p"/admin/profile"}
                  icon="hero-user-circle"
                  label="My Profile"
                />

                <.admin_menu_item href={~p"/admin/settings"} icon="hero-cog-6-tooth" label="Settings" />

                <li class="border-t border-[#E5E7EB] mt-1 pt-1">
                  <.link
                    href={~p"/users/log-out"}
                    method="delete"
                    class="flex items-center gap-2 px-3 py-2 rounded-lg text-red-600 hover:bg-red-50 transition-colors"
                  >
                    <.icon name="hero-arrow-right-on-rectangle" class="size-4" /> Log out
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
        <label for="admin-sidebar" aria-label="Close sidebar" class="drawer-overlay"></label>

        <aside class="admin-sidebar min-h-full w-72 bg-white border-r border-[#E5E7EB] flex flex-col">
          <%!-- ADMIN BRAND --%>
          <div class="admin-sidebar-brand h-16 px-5 flex items-center gap-3 border-b border-[#E5E7EB] shrink-0">
            <div class="admin-sidebar-brand-mark w-9 h-9 rounded-lg bg-[#0B2E4F] text-white flex items-center justify-center">
              <.icon name="hero-book-open" class="size-5" />
            </div>

            <div class="admin-sidebar-brand-copy min-w-0 flex-1">
              <p class="font-bold text-sm tracking-tight text-[#0B2E4F]">
                OpenForum
              </p>

              <p class="text-[0.65rem] uppercase tracking-wider text-[#6B7280]">
                Administration
              </p>
            </div>

            <label
              for="admin-sidebar-collapse"
              title="Collapse sidebar"
              aria-label="Toggle sidebar width"
              class="admin-sidebar-collapse-button hidden lg:flex size-7 shrink-0 cursor-pointer items-center justify-center rounded-lg text-[#718096] transition hover:bg-[#EAF3F8] hover:text-[#1769AA]"
            >
              <.icon name="hero-chevron-double-left" class="admin-sidebar-collapse-icon size-4" />
              <.icon name="hero-chevron-double-right" class="admin-sidebar-expand-icon size-4" />
            </label>
          </div>

          <%!-- SIDEBAR NAVIGATION --%>
          <nav class="flex-1 px-3 py-5 overflow-y-auto">
            <.sidebar_group
              label="Overview"
              icon="hero-squares-2x2"
              active={@current_page == :dashboard}
              open={@current_page == :dashboard}
            >
              <.sidebar_link
                href={~p"/admin/dashboard"}
                icon="hero-squares-2x2"
                label="Dashboard"
                active={@current_page == :dashboard}
              />
            </.sidebar_group>

            <.sidebar_group
              label="Content"
              icon="hero-folder-open"
              active={@current_page in [:content, :documents, :approval_queue, :published, :media]}
              open={@current_page in [:content, :documents, :approval_queue, :published, :media]}
            >
              <.sidebar_link
                href={~p"/admin/content"}
                icon="hero-document-text"
                label="All Content"
                active={@current_page == :content}
              />
              <.sidebar_link
                href={~p"/admin/documents"}
                icon="hero-pencil-square"
                label="Documents"
                active={@current_page == :documents}
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
            </.sidebar_group>

            <.sidebar_group
              label="Knowledge"
              icon="hero-academic-cap"
              active={
                @current_page in [
                  :bible,
                  :doctrine,
                  :catechism,
                  :questions_and_answers,
                  :learning_paths
                ]
              }
              open={
                @current_page in [
                  :bible,
                  :doctrine,
                  :catechism,
                  :questions_and_answers,
                  :learning_paths
                ]
              }
            >
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
            </.sidebar_group>

            <.sidebar_group
              label="Workflow"
              icon="hero-arrows-right-left"
              active={@current_page in [:workflows, :reviews, :audit_logs]}
              open={@current_page in [:workflows, :reviews, :audit_logs]}
            >
              <.sidebar_link
                href={~p"/admin/work_flows"}
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
            </.sidebar_group>

            <.sidebar_group
              label="Organisation"
              icon="hero-building-office-2"
              active={@current_page in [:working_areas, :area_lead, :area_leads]}
              open={@current_page in [:working_areas, :area_lead, :area_leads]}
            >
              <.sidebar_link
                href={~p"/admin/working_areas"}
                icon="hero-building-office-2"
                label="Working Areas"
                active={@current_page == :working_areas}
              />
              <.sidebar_link
                href={~p"/admin/area_leads"}
                icon="hero-users"
                label="Area Leads"
                active={@current_page in [:area_lead, :area_leads]}
              />
            </.sidebar_group>

            <.sidebar_group
              label="Access"
              icon="hero-shield-check"
              active={@current_page in [:users, :roles, :roles_permissions]}
              open={@current_page in [:users, :roles, :roles_permissions]}
            >
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
                active={@current_page in [:roles, :roles_permissions]}
              />
            </.sidebar_group>

            <.sidebar_group
              label="System"
              icon="hero-cog-6-tooth"
              active={@current_page == :settings}
              open={@current_page == :settings}
            >
              <.sidebar_link
                href={~p"/admin/settings"}
                icon="hero-cog-6-tooth"
                label="Settings"
                active={@current_page == :settings}
              />
            </.sidebar_group>
          </nav>

          <%!-- SIDEBAR FOOTER --%>
          <div class="p-3 border-t border-[#E5E7EB] shrink-0">
            <.link
              href={~p"/users/log-out"}
              method="delete"
              class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-[#6B7280] hover:bg-red-50 hover:text-red-600 transition-colors"
            >
              <.icon name="hero-arrow-right-on-rectangle" class="size-4" />
              <span class="admin-sidebar-label">Log out</span>
            </.link>

            <p class="admin-sidebar-copyright text-[0.65rem] text-[#9CA3AF] mt-3 px-3">
              © {Date.utc_today().year} OpenForum
            </p>
          </div>
        </aside>
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".AdminSidebarCollapse">
      export default {
        mounted() {
          const storageKey = "openforum-admin-sidebar-collapsed"

          try {
            this.el.checked = window.localStorage.getItem(storageKey) === "true"
          } catch (_error) {
            this.el.checked = false
          }

          this.onChange = () => {
            try {
              window.localStorage.setItem(storageKey, String(this.el.checked))
            } catch (_error) {
              // Keep the control usable when browser storage is unavailable.
            }
          }

          this.el.addEventListener("change", this.onChange)
        },

        destroyed() {
          this.el.removeEventListener("change", this.onChange)
        }
      }
    </script>
    """
  end

  attr :id, :string, required: true

  def theme_toggle(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      phx-hook=".ThemeToggle"
      aria-label="Toggle light and dark theme"
      title="Toggle light and dark theme"
      class="flex size-10 shrink-0 items-center justify-center border border-[#E5E7EB] text-[#0B2E4F] transition duration-200 hover:bg-[#EAF3F8] hover:text-[#1769AA] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#1769AA]"
    >
      <.icon name="hero-moon" class="size-4 dark:hidden" />
      <.icon name="hero-sun" class="hidden size-4 dark:block" />
    </button>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ThemeToggle">
      export default {
        mounted() {
          this.onClick = () => {
            const currentTheme = document.documentElement.getAttribute("data-theme") || "light"
            this.el.dataset.phxTheme = currentTheme === "dark" ? "light" : "dark"
            this.el.dispatchEvent(new Event("phx:set-theme", { bubbles: true }))
          }

          this.el.addEventListener("click", this.onClick)
        },

        destroyed() {
          this.el.removeEventListener("click", this.onClick)
        }
      }
    </script>
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
                <.icon name="hero-book-open" class="size-5 text-[#C9A227]" />
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
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide(".phx-client-error #client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide(".phx-server-error #server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
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
        if(@active,
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
  attr :icon, :string, required: true
  attr :active, :boolean, default: false
  attr :open, :boolean, default: false
  slot :inner_block, required: true

  defp sidebar_group(assigns) do
    ~H"""
    <details class="admin-sidebar-section group/section" open={@open}>
      <summary
        title={@label}
        aria-label={@label}
        class={[
          "admin-sidebar-section-summary mb-1 flex cursor-pointer list-none items-center gap-2.5 rounded-xl px-3 py-2.5 text-[0.69rem] font-bold uppercase tracking-[0.12em] transition-all duration-200 [&::-webkit-details-marker]:hidden",
          if(@active,
            do: "bg-[#EAF3F8] text-[#1769AA] shadow-sm shadow-[#0B2E4F]/5",
            else: "text-[#718096] hover:bg-[#F4F8FB] hover:text-[#34495E]"
          )
        ]}
      >
        <.icon name={@icon} class="size-4 shrink-0" />
        <span class="admin-sidebar-group min-w-0 flex-1 truncate">{@label}</span>
        <span
          :if={@active}
          class="size-1.5 shrink-0 rounded-full bg-[#1769AA] shadow-[0_0_0_3px_rgba(23,105,170,0.12)]"
        />
        <.icon
          name="hero-chevron-down"
          class="admin-sidebar-section-chevron size-3 shrink-0 text-[#9AA8B5] transition-transform duration-200 group-open/section:rotate-180"
        />
      </summary>

      <div class="admin-sidebar-section-links ml-3 border-l border-[#E5E7EB] pl-2">
        {render_slot(@inner_block)}
      </div>
    </details>
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
      title={@label}
      aria-label={@label}
      aria-current={if(@active, do: "page")}
      class={[
        "admin-sidebar-link flex items-center gap-3 px-3 py-2.5 rounded-lg text-[0.82rem] border-l-[3px] transition-colors mb-1",
        if(@active,
          do:
            "font-semibold text-[#0B2E4F] bg-[#EAF3F8] border-[#1769AA] shadow-sm shadow-[#0B2E4F]/5",
          else:
            "font-medium text-[#4B5563] border-transparent hover:bg-[#F4F8FB] hover:text-[#1769AA]"
        )
      ]}
    >
      <.icon name={@icon} class="size-4 shrink-0" />

      <span class="admin-sidebar-label min-w-0 truncate">
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

  # ───────────────────────────────────────────────
  #  USER AVATAR (photo, or initials fallback)
  # ───────────────────────────────────────────────

  attr :user, :map, required: true
  attr :size, :string, default: "w-8 h-8 text-xs"

  defp user_avatar(assigns) do
    ~H"""
    <img
      :if={Map.get(@user, :avatar_url) not in [nil, ""]}
      src={@user.avatar_url}
      alt={"#{@user.first_name} #{@user.last_name}"}
      class={["rounded-full object-cover shrink-0", @size]}
    />

    <div
      :if={Map.get(@user, :avatar_url) in [nil, ""]}
      class={[
        "rounded-full bg-[#0B2E4F] text-white flex items-center justify-center font-bold shrink-0",
        @size
      ]}
    >
      {user_initials(@user)}
    </div>
    """
  end

  # ───────────────────────────────────────────────
  #  USER INITIALS
  # ───────────────────────────────────────────────

  defp user_initials(%{first_name: first, last_name: last})
       when is_binary(first) and byte_size(first) > 0 and
              is_binary(last) and byte_size(last) > 0 do
    String.first(first) <> String.first(last)
  end

  defp user_initials(_user), do: "?"

  # ───────────────────────────────────────────────
  #  ROLE LABEL
  # ───────────────────────────────────────────────

  defp role_label(roles) when is_list(roles) and roles != [] do
    roles |> Enum.map(& &1.name) |> Enum.join(", ")
  end

  defp role_label(_roles), do: "No role assigned"
end
