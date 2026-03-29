defmodule PhoenixKitUserConnections.FollowHistory do
  @moduledoc """
  Schema for follow activity history.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias PhoenixKit.Utils.Date, as: UtilsDate

  @primary_key {:uuid, UUIDv7, autogenerate: true}
  @foreign_key_type UUIDv7

  schema "phoenix_kit_user_follows_history" do
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

    field(:action, :string)
    field(:inserted_at, :utc_datetime)
  end

  @actions ~w(follow unfollow)

  def changeset(history, attrs) do
    history
    |> cast(attrs, [:follower_uuid, :followed_uuid, :action])
    |> validate_required([:follower_uuid, :followed_uuid, :action])
    |> validate_inclusion(:action, @actions)
    |> put_timestamp()
    |> foreign_key_constraint(:follower_uuid)
    |> foreign_key_constraint(:followed_uuid)
  end

  defp put_timestamp(changeset) do
    put_change(changeset, :inserted_at, UtilsDate.utc_now())
  end
end
