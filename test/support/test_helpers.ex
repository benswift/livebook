defmodule Livebook.TestHelpers do
  @moduledoc false

  import Phoenix.LiveViewTest

  alias Livebook.Session.Data

  @doc """
  Creates file structure according to the given specification.
  """
  def create_tree!(path, items) do
    for {name, content} <- items do
      child_path = Path.join(path, to_string(name))

      case content do
        items when is_list(items) ->
          File.mkdir!(child_path)
          create_tree!(child_path, items)

        content when is_binary(content) ->
          File.write!(child_path, content)
      end
    end
  end

  @doc """
  Applies the given list of operations to `Livebook.Session.Data`.

  Raises if any of the operations results in an error.
  """
  def data_after_operations!(data \\ Data.new(), operations) do
    operations
    |> List.flatten()
    |> Enum.reduce(data, fn operation, data ->
      case Data.apply_operation(data, operation) do
        {:ok, data, _action} ->
          data

        :error ->
          raise "failed to set up test data, operation #{inspect(operation)} returned an error"
      end
    end)
  end

  @doc """
  Converts a Unix-like absolute path into OS-compatible absolute path.
  """
  defmacro p("/" <> path), do: Path.expand("/") <> path

  @doc """
  Confirms the action guarded by `LivebookWeb.Confirm/3` and
  returns the rendered result.
  """
  def render_confirm(view) do
    view
    |> element(~s/[data-el-confirm-form]/)
    |> render_submit()
  end

  @doc """
  Builds code that renders the given output as part of evaluation.
  """
  def source_for_output(output) do
    quote do
      send(
        Process.group_leader(),
        {:io_request, self(), make_ref(), {:livebook_put_output, unquote(Macro.escape(output))}}
      )
    end
    |> Macro.to_string()
  end
end
