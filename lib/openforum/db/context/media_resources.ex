defmodule Openforum.Context.MediaResources do
  import Ecto.Query, warn: false

  alias Openforum.Repo
  alias Openforum.Schema.MediaResource

  def list_for_uploader(user) do
    MediaResource
    |> where([resource], resource.uploaded_by_id == ^user.id)
    |> order_by([resource], desc: resource.inserted_at, desc: resource.id)
    |> preload(:category)
    |> Repo.all()
  end

  def list_public do
    MediaResource
    |> where([resource], resource.status == "published")
    |> order_by([resource], desc: resource.inserted_at, desc: resource.id)
    |> preload(:category)
    |> Repo.all()
  end

  def create(user, attrs) do
    %MediaResource{}
    |> MediaResource.changeset(attrs)
    |> Ecto.Changeset.put_change(:uploaded_by_id, user.id)
    |> Repo.insert()
  end

  def get_for_uploader!(user, id) do
    MediaResource
    |> where([resource], resource.id == ^id and resource.uploaded_by_id == ^user.id)
    |> Repo.one!()
  end

  def update_status(%MediaResource{} = resource, status) do
    resource
    |> Ecto.Changeset.change(status: status)
    |> Ecto.Changeset.validate_inclusion(:status, MediaResource.statuses())
    |> Repo.update()
  end

  def delete(%MediaResource{} = resource), do: Repo.delete(resource)
end
