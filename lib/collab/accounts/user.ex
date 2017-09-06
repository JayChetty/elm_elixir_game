defmodule Collab.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Collab.Accounts.User


  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :password_hash])
    |> validate_required([:email])
    |> unique_constraint(:email)

  end

  def registration_changeset(%User{} = user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_length(:password, min: 8)
    |> put_pass_hash()
  end

  def put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        changeset
          |> put_change(:password_hash, Comeonin.Bcrypt.hashpwsalt(password))
          |> put_change(:password, nil)
      _ ->
        changeset
    end
  end
end
