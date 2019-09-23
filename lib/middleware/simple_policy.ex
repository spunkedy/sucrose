defmodule Sucrose.Middleware.SimplePolicy do
  alias Absinthe.Resolution
  require Logger

  @behaviour Absinthe.Middleware
  @moduledoc """
  This is a simple policy handler that takes a very simple approach to absinthe resolution handling
  The basis for all of the handlers is to have a common response type:

  true, false, :ok, :error, {:ok, _}, {:error, message}

  """

  @error_message :no_proper_resolution_or_config

  def call(resolution = %{context: %{claim: _}}, %{handler: handler}) do
    check = simple_resolution(resolution)

    response =
      case check do
        %{parent: :mutation} -> handler.can_mutate?(check)
        _ -> handler.can_query?(check)
      end

    case response do
      {:ok, _} -> resolution
      :ok -> resolution
      true -> resolution
      {:error, msg} -> handle_error(check, msg)
      _ -> handle_error(check)
    end
  rescue
    _ ->
      {:error, @error_message}
  end

  def call(_, _) do
    {:error, @error_message}
  end

  @doc """
  This is the default error handler to put when we want to deny something.
  """
  def handle_error(check, message \\ "Unauthorized") do
    Logger.warn(fn ->
      "Erroring out for: #{inspect(Map.take(check, [:child, :parent, :claim]))}"
    end)

    Resolution.put_result(check.resolution, {:error, message})
  end

  @spec simple_resolution(map()) :: %{
          child: :atom,
          parent: :atom,
          claim: any(),
          resolution: map()
        }
  def simple_resolution(resolution) do
    %{
      child: resolution.definition.schema_node.identifier,
      parent: resolution.parent_type.identifier,
      claim: resolution.context.claim,
      resolution: resolution
    }
  end
end
