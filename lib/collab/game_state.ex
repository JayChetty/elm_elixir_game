defmodule Collab.GameState do
  @doc """
  Start the Game with no players.
  """
  @spec start_link() :: any
  def start_link() do
    Agent.start_link(fn -> %{players: []} end, name: __MODULE__)
  end


  @doc """
  Add player to the game
  """
  @spec add_player(Map) :: any
  def add_player(player) do
    Agent.get_and_update(__MODULE__,  fn state ->
      { :ok, %{ state | players: [ player | state.players ] } }
    end)
    # Agent.update(account, fn state ->  %{state | balance: state.balance + amount} end)
  end

  @doc """
    Get the players
  """
  @spec players() :: List
  def players() do
    Agent.get(__MODULE__,  fn state ->
      state.players
    end)
  end

end
