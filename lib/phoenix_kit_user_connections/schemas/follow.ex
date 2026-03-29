defmodule PhoenixKitUserConnections.Follow do
  @moduledoc """
  Schema for one-way follow relationships.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias PhoenixKit.Utils.Date, as: UtilsDate

  @primary_key {:uuid, UUIDv7, autogenerate: true}

  @type t :: %__MODULE__{
          uuid: UUIDv7.t() | nil,
          follower_uuid: UUIDv7.t(),
          followed_uuid: UUIDv7.t(),
          follower: PhoenixKit.Users.Auth.User.t() | Ecto.Association.NotLoaded.t(),
          followed: PhoenixKit.Users.Auth.User.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil
        }

  schema "phoenix_kit_user_follows" do
    belongs_to(:follower, PhoenixKit.Users.Auth.User,
      foreign_key: :follower_uuid,
      references: :uuid,
      type: UUIDv7
    )

    belongs_to(:followed, PhoenixKit.Users.Auth.User,
      foreign_key: :followed_uuid,
      references: :uuid,
      type: UUIDv7
    )

    field(:inserted_at, :utc_datetime)
  end

  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:follower_uuid, :followed_uuid])
    |> validate_required([:follower_uuid, :followed_uuid])
    |> validate_not_self_follow()
    |> put_inserted_at()
    |> foreign_key_constraint(:follower_uuid)
    |> foreign_key_constraint(:followed_uuid)
    |> unique_constraint([:follower_uuid, :followed_uuid],
      name: :phoenix_kit_user_follows_unique_idx,
      message: "already following this user"
    )
  end

  defp validate_not_self_follow(changeset) do
    follower_uuid = get_field(changeset, :follower_uuid)
    followed_uuid = get_field(changeset, :followed_uuid)

    if follower_uuid && followed_uuid && follower_uuid == followed_uuid do
      add_error(changeset, :followed_uuid, "cannot follow yourself")
    else
      changeset
    end
  end

  defp put_inserted_at(changeset) do
    if get_field(changeset, :inserted_at) do
      changeset
    else
      put_change(changeset, :inserted_at, UtilsDate.utc_now())
    end
  end
end
