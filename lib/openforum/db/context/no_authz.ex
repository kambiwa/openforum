defmodule Openforum.NotAuthorizedError do
  @moduledoc """
  Raised by `Openforum.Context.Authz.require_permission!/3` when a user
  lacks the required category/action permission. Maps to a 403 when it
  reaches Phoenix's error views.
  """
  defexception message: "not authorized", plug_status: 403
end
