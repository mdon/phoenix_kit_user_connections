defmodule PhoenixKitUserConnections.Web.Connections do
  @moduledoc """
  Admin LiveView for the Connections module.
  """

  use PhoenixKitWeb, :live_view

  alias PhoenixKit.Settings
  alias PhoenixKit.Users.Auth.Scope
  alias PhoenixKit.Utils.Routes

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns[:phoenix_kit_current_scope]

    cond do
      not PhoenixKitUserConnections.enabled?() ->
        {:ok,
         socket
         |> put_flash(:error, "Connections module is not enabled")
         |> push_navigate(to: Routes.path("/admin"))}

      not (scope && Scope.has_module_access?(scope, "connections")) ->
        {:ok,
         socket
         |> put_flash(:error, "Access denied")
         |> push_navigate(to: Routes.path("/admin"))}

      true ->
        project_title = Settings.get_project_title()

        socket =
          socket
          |> assign(:page_title, "Connections")
          |> assign(:project_title, project_title)
          |> load_stats()

        {:ok, socket}
    end
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, assign(socket, :url_path, URI.parse(uri).path)}
  end

  @impl true
  def handle_event("toggle_enabled", _params, socket) do
    case check_authorization(socket) do
      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Not authorized")}

      :ok ->
        do_toggle_enabled(socket)
    end
  end

  defp do_toggle_enabled(socket) do
    new_value = !socket.assigns.enabled

    result =
      if new_value do
        PhoenixKitUserConnections.enable_system()
      else
        PhoenixKitUserConnections.disable_system()
      end

    case result do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           if(new_value, do: "Connections enabled", else: "Connections disabled")
         )
         |> assign(:enabled, new_value)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update setting")}
    end
  end

  defp check_authorization(socket) do
    scope = socket.assigns[:phoenix_kit_current_scope]

    if scope && Scope.has_module_access?(scope, "connections") do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  defp load_stats(socket) do
    socket
    |> assign(:enabled, PhoenixKitUserConnections.enabled?())
    |> assign(:stats, PhoenixKitUserConnections.get_stats())
  end
end
