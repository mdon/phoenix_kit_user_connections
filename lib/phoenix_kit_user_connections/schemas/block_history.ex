defmodule PhoenixKitUserConnections.BlockHistory do
  @moduledoc """
  Schema for block activity history.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias PhoenixKit.Utils.Date, as: UtilsDate

  @primary_key {:uuid, UUIDv7, autogenerate: true}
  @foreign_key_type UUIDv7

  schema "phoenix_kit_user_blocks_history" do
    belongs_to(:blocker, PhoenixKit.Users.Auth.User,
      foreign_key: :blocker_uuid,
      references: :uuid,
      type: UUIDv7
    )

    belongs_to(:blocked, PhoenixKit.Users.Auth.User,
      foreign_key: :blocked_uuid,
      references: :uuid,
      type: UUIDv7
    )

    field(:action, :string)
    field(:reason, :string)
    field(:inserted_at, :utc_datetime)
  end

  @actions ~w(block unblock)

  def changeset(history, attrs) do
    history
    |> cast(attrs, [:blocker_uuid, :blocked_uuid, :action, :reason])
    |> validate_required([:blocker_uuid, :blocked_uuid, :action])
    |> validate_inclusion(:action, @actions)
    |> put_timestamp()
    |> foreign_key_constraint(:blocker_uuid)
    |> foreign_key_constraint(:blocked_uuid)
  end

  defp put_timestamp(changeset) do
    put_change(changeset, :inserted_at, UtilsDate.utc_now())
  end
end
