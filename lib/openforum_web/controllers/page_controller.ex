defmodule OpenforumWeb.PageController do
  use OpenforumWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
