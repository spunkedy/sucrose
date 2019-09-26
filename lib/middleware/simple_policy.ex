defmodule Sucrose.Middleware.SimplePolicy do
  alias Absinthe.Resolution
  alias Sucrose.Common

  @behaviour Absinthe.Middleware
  @moduledoc """
  This is a simple policy handler that takes a very simple approach to absinthe resolution handling
  The basis for all of the handlers is to have a common response type:

  To use this policy you must return the common return handler.
  `Sucrose.Common.handle_response/2`
  """

  @error_message :no_proper_resolution_or_config

  def call(resolution = %{context: %{claim: _}}, %{handler: handler}) do
    check = simple_resolution(resolution)

    response =
      case check do
        %{parent: :mutation} -> handler.can_mutate?(check)
        _ -> handler.can_query?(check)
      end

    Common.handle_response(response, check)
  rescue
    _ ->
      {:error, @error_message}
  end

  def call(_, _) do
    {:error, @error_message}
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
