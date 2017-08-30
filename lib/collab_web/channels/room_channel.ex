defmodule CollabWeb.RoomChannel do
  use Phoenix.Channel
  import Logger

  def join("room:lobby", message, socket) do
    Logger.warn("JOINING message #{inspect message}")
    # Logger.warn("JOINING socket #{inspect socket}")
    socket = assign(socket, :players, [%{name: "DUMMY PLAYER"}])
    send(self, :after_join)
    {:ok, socket}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_info(:after_join, socket) do
    broadcast! socket, "new_user", %{players: socket.assigns.players}
    {:noreply, socket}
  end

  def handle_in("new_msg", %{}, socket) do
    broadcast! socket, "new_msg", %{body: "lalala"}
    {:noreply, socket}
  end
end
