defmodule RauversionWeb.TrackLive.Show do
  use RauversionWeb, :live_view

  alias Rauversion.{Tracks, Repo, Accounts}
  alias RauversionWeb.TrackLive.Step

  @impl true
  def mount(_params, session, socket) do
    socket =
      RauversionWeb.LiveHelpers.get_user_by_session(socket, session)
      |> assign(:share_track, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(
        %{"id" => id} = _params,
        _,
        socket = %{assigns: %{live_action: :show, current_user: _user = nil}}
      ) do
    track = Tracks.get_track!(id) |> Repo.preload(:user)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:track, track)}
  end

  @impl true
  def handle_params(
        %{"id" => id} = _params,
        _,
        socket = %{assigns: %{live_action: :show, current_user: user = %Accounts.User{}}}
      ) do
    track =
      Tracks.get_track!(id)
      |> Rauversion.Tracks.preload_tracks_preloaded_by_user(user)
      |> Rauversion.Repo.preload([:user])

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:track, track)}
  end

  @impl true
  def handle_params(
        %{"id" => signed_id} = _params,
        _,
        socket = %{assigns: %{live_action: :private}}
      ) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:track, Rauversion.Tracks.find_by_signed_id!(signed_id) |> Repo.preload(:user))}
  end

  @impl true
  def handle_params(%{"id" => id} = _params, _, socket = %{assigns: %{live_action: :edit}}) do
    socket =
      socket
      |> assign(:step, %Step{name: "info", prev: "upload", next: "share"})
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:current_tab, "basic-info-tab")
      |> assign(:track, Tracks.get_track!(id) |> Repo.preload(:user))

    case RauversionWeb.LiveHelpers.authorize_user_resource(socket, socket.assigns.track.user_id) do
      {:ok, socket} ->
        {:noreply, socket}

      {:err, err} ->
        {:noreply, err}
    end
  end

  @impl true
  def handle_event("metadata-tab" = tab, _, socket) do
    {:noreply, socket |> assign(:current_tab, tab)}
  end

  @impl true
  def handle_event("basic-info-tab" = tab, _, socket) do
    {:noreply, socket |> assign(:current_tab, tab)}
  end

  @impl true
  def handle_event("permissions-tab" = tab, _, socket) do
    {:noreply, socket |> assign(:current_tab, tab)}
  end

  @impl true
  def handle_event("share-tab" = tab, _, socket) do
    {:noreply, socket |> assign(:current_tab, tab)}
  end

  @impl true
  def handle_event("share-track-modal", %{"id" => id}, socket) do
    {:noreply,
     assign(
       socket,
       :share_track,
       Tracks.get_track!(id) |> Rauversion.Repo.preload(user: :avatar_attachment)
     )}
  end

  defp page_title(:private), do: "Show Track · private preview"
  defp page_title(:show), do: "Show Track"
  defp page_title(:edit), do: "Edit Track"
end
