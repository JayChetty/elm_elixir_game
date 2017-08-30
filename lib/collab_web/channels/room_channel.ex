defmodule CollabWeb.RoomChannel do
  use Phoenix.Channel
  import Logger
  alias Collab.GameState

  def join("room:lobby", message, socket) do
    send(self, {:after_join, message})
    {:ok, socket}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info({:after_join, player}, socket) do
    GameState.add_player( player )
    broadcast! socket, "new:player", %{players: GameState.players()}
    {:noreply, socket}
  end

  def handle_in("new_msg", %{}, socket) do
    count = Map.get(socket.assigns, :ping_count, 0)
    socket = assign(socket, :ping_count, count + 1)
    broadcast! socket, "new_msg", %{body: socket.assigns.ping_count}
    {:noreply, socket}
  end
end
