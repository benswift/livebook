defmodule LivebookWeb.AppHelpers do
  use LivebookWeb, :html

  @doc """
  Renders page placeholder on unauthenticated dead render.
  """
  def auth_placeholder(assigns) do
    ~H"""
    <div class="flex justify-center items-center h-screen w-screen">
      <img src={~p"/images/logo.png"} height="128" width="128" alt="livebook" class="animate-pulse" />
    </div>
    """
  end

  @doc """
  Renders app status with indicator.
  """
  attr :status, :atom, required: true
  attr :show_label, :boolean, default: true

  def app_status(%{status: :executing} = assigns) do
    ~H"""
    <.app_status_indicator text={@show_label && "Executing"} variant={:progressing} />
    """
  end

  def app_status(%{status: :executed} = assigns) do
    ~H"""
    <.app_status_indicator text={@show_label && "Executed"} variant={:success} />
    """
  end

  def app_status(%{status: :error} = assigns) do
    ~H"""
    <.app_status_indicator text={@show_label && "Error"} variant={:error} />
    """
  end

  def app_status(%{status: :shutting_down} = assigns) do
    ~H"""
    <.app_status_indicator text={@show_label && "Shutting down"} variant={:inactive} />
    """
  end

  def app_status(%{status: :deactivated} = assigns) do
    ~H"""
    <.app_status_indicator text={@show_label && "Deactivated"} variant={:inactive} />
    """
  end

  defp app_status_indicator(assigns) do
    ~H"""
    <span class="flex items-center space-x-2">
      <span :if={@text}><%= @text %></span>
      <.status_indicator variant={@variant} />
    </span>
    """
  end

  @doc """
  Shows a confirmation modal and closes the app on confirm.
  """
  def confirm_app_termination(socket, app_pid) do
    on_confirm = fn socket ->
      Livebook.App.close(app_pid)
      socket
    end

    confirm(socket, on_confirm,
      title: "Terminate app",
      description: "All app sessions will be immediately terminated.",
      confirm_text: "Terminate",
      confirm_icon: "delete-bin-6-line"
    )
  end
end
