defmodule Collab.AccountsTest do
  use Collab.DataCase
  alias Collab.Accounts

  describe "users" do
    alias Auth.Accounts.User

    @valid_attrs %{email: "person@email.com", password: "password"}
    @update_attrs %{email: "updated@email.com"}
    @invalid_attrs %{email: nil, password_hash: nil}


    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()
      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "person@email.com"
      assert user.password_hash
      assert String.length(user.password_hash) > 16
    end

    test "create_user/1 with short password data returns error changeset" do
      short_password_attrs = %{ @valid_attrs | password: "pass" }
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(short_password_attrs)
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "create_user/1 with taken email returns error changeset" do
      {:ok, %User{} = _} = Accounts.create_user(@valid_attrs)
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@valid_attrs)
    end


    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Accounts.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.email == "updated@email.com"
      assert user.password_hash
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "authenticate_user/1 returns ok when correct username password" do
      user = user_fixture()
      assert {:ok, found_user} = Accounts.authenticate_user(@valid_attrs)
      assert user == found_user
    end

    test "authenticate_user/1 returns error when incorrect password" do
      _ = user_fixture()
      wrong_password_attrs = %{@valid_attrs | password: "hackerz"}
      assert :error = Accounts.authenticate_user(wrong_password_attrs)
    end

    test "authenticate_user/1 returns error when can't find user" do
      _ = user_fixture()
      no_email_attrs = %{@valid_attrs | email: "doesntexist@email.com"}
      assert :error = Accounts.authenticate_user(no_email_attrs)
    end
  end
end
