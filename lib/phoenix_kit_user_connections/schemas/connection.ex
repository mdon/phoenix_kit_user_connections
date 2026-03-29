defmodule PhoenixKitUserConnections.Connection do
  @moduledoc """
  Schema for two-way mutual connection relationships.

  Represents a bidirectional relationship that requires acceptance from both parties.

  ## Status Flow

  - `pending` - Request sent, awaiting response
  - `accepted` - Both parties have agreed to connect
  - `rejected` - Recipient declined the request
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias PhoenixKit.Utils.Date, as: UtilsDate

  @primary_key {:uuid, UUIDv7, autogenerate: true}

  @statuses ["pending", "accepted", "rejected"]

  @type status :: String.t()

  @type t :: %__MODULE__{
          uuid: UUIDv7.t() | nil,
          requester_uuid: UUIDv7.t(),
          recipient_uuid: UUIDv7.t(),
          status: status(),
          requested_at: DateTime.t(),
          responded_at: DateTime.t() | nil,
          requester: PhoenixKit.Users.Auth.User.t() | Ecto.Association.NotLoaded.t(),
          recipient: PhoenixKit.Users.Auth.User.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "phoenix_kit_user_connections" do
    belongs_to(:requester, PhoenixKit.Users.Auth.User,
      foreign_key: :requester_uuid,
      references: :uuid,
      type: UUIDv7
    )

    belongs_to(:recipient, PhoenixKit.Users.Auth.User,
      foreign_key: :recipient_uuid,
      references: :uuid,
      type: UUIDv7
    )

    field(:status, :string, default: "pending")
    field(:requested_at, :utc_datetime)
    field(:responded_at, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [:requester_uuid, :recipient_uuid, :status, :requested_at, :responded_at])
    |> validate_required([:requester_uuid, :recipient_uuid])
    |> validate_inclusion(:status, @statuses)
    |> validate_not_self_connection()
    |> put_requested_at()
    |> foreign_key_constraint(:requester_uuid)
    |> foreign_key_constraint(:recipient_uuid)
  end

  def status_changeset(connection, attrs) do
    connection
    |> cast(attrs, [:status, :responded_at])
    |> validate_required([:status])
    |> validate_inclusion(:status, @statuses)
    |> put_responded_at()
  end

  defp validate_not_self_connection(changeset) do
    requester_uuid = get_field(changeset, :requester_uuid)
    recipient_uuid = get_field(changeset, :recipient_uuid)

    if requester_uuid && recipient_uuid && requester_uuid == recipient_uuid do
      add_error(changeset, :recipient_uuid, "cannot connect with yourself")
    else
      changeset
    end
  end

  defp put_requested_at(changeset) do
    if get_field(changeset, :requested_at) do
      changeset
    else
      put_change(changeset, :requested_at, UtilsDate.utc_now())
    end
  end

  defp put_responded_at(changeset) do
    status = get_change(changeset, :status)

    if status in ["accepted", "rejected"] && !get_field(changeset, :responded_at) do
      put_change(changeset, :responded_at, UtilsDate.utc_now())
    else
      changeset
    end
  end

  def pending?(%__MODULE__{status: "pending"}), do: true
  def pending?(_), do: false

  def accepted?(%__MODULE__{status: "accepted"}), do: true
  def accepted?(_), do: false

  def rejected?(%__MODULE__{status: "rejected"}), do: true
  def rejected?(_), do: false
end
