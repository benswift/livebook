defmodule LivebookWeb.SessionLive.CellComponent do
  use LivebookWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="flex flex-col relative"
      data-el-cell
      id={"cell-#{@cell_view.id}"}
      phx-hook="Cell"
      data-cell-id={@cell_view.id}
      data-focusable-id={@cell_view.id}
      data-type={@cell_view.type}
      data-session-path={~p"/sessions/#{@session_id}"}
      data-evaluation-digest={get_in(@cell_view, [:eval, :evaluation_digest])}
      data-eval-validity={get_in(@cell_view, [:eval, :validity])}
      data-eval-errored={get_in(@cell_view, [:eval, :errored])}
      data-js-empty={empty?(@cell_view.source_view)}
      data-smart-cell-js-view-ref={smart_cell_js_view_ref(@cell_view)}
      data-allowed-uri-schemes={Enum.join(@allowed_uri_schemes, ",")}
    >
      <%= render_cell(assigns) %>
    </div>
    """
  end

  defp render_cell(%{cell_view: %{type: :markdown}} = assigns) do
    ~H"""
    <.cell_actions>
      <:secondary>
        <.enable_insert_mode_button />
        <.cell_link_button cell_id={@cell_view.id} />
        <.move_cell_up_button cell_id={@cell_view.id} />
        <.move_cell_down_button cell_id={@cell_view.id} />
        <.delete_cell_button cell_id={@cell_view.id} />
      </:secondary>
    </.cell_actions>
    <.cell_body>
      <div class="pb-4" data-el-editor-box>
        <.live_component
          module={LivebookWeb.SessionLive.CellEditorComponent}
          id={"#{@cell_view.id}-primary"}
          cell_id={@cell_view.id}
          tag="primary"
          source_view={@cell_view.source_view}
          language="markdown"
        />
      </div>
      <div
        class="markdown"
        data-el-markdown-container
        id={"markdown-container-#{@cell_view.id}"}
        phx-update="ignore"
      >
        <.content_skeleton empty={empty?(@cell_view.source_view)} />
      </div>
    </.cell_body>
    """
  end

  defp render_cell(%{cell_view: %{type: :code}} = assigns) do
    ~H"""
    <.cell_actions>
      <:primary>
        <.cell_evaluation_button
          session_id={@session_id}
          cell_id={@cell_view.id}
          validity={@cell_view.eval.validity}
          status={@cell_view.eval.status}
          reevaluate_automatically={@cell_view.reevaluate_automatically}
          reevaluates_automatically={@cell_view.eval.reevaluates_automatically}
        />
      </:primary>
      <:secondary>
        <.amplify_output_button />
        <.cell_settings_button cell_id={@cell_view.id} session_id={@session_id} />
        <.cell_link_button cell_id={@cell_view.id} />
        <.move_cell_up_button cell_id={@cell_view.id} />
        <.move_cell_down_button cell_id={@cell_view.id} />
        <.delete_cell_button cell_id={@cell_view.id} />
      </:secondary>
    </.cell_actions>
    <.cell_body>
      <div class="relative">
        <.live_component
          module={LivebookWeb.SessionLive.CellEditorComponent}
          id={"#{@cell_view.id}-primary"}
          cell_id={@cell_view.id}
          tag="primary"
          source_view={@cell_view.source_view}
          language="elixir"
          intellisense
        />
        <div class="absolute bottom-2 right-2">
          <.cell_status id={@cell_view.id} cell_view={@cell_view} />
        </div>
      </div>
      <.evaluation_outputs
        cell_view={@cell_view}
        session_id={@session_id}
        session_pid={@session_pid}
        client_id={@client_id}
      />
    </.cell_body>
    """
  end

  defp render_cell(%{cell_view: %{type: :setup}} = assigns) do
    ~H"""
    <.cell_actions>
      <:primary>
        <.setup_cell_evaluation_button
          cell_id={@cell_view.id}
          validity={@cell_view.eval.validity}
          status={@cell_view.eval.status}
          runtime={@runtime}
        />
      </:primary>
      <:secondary>
        <.package_search_button session_id={@session_id} runtime={@runtime} />
        <.cell_link_button cell_id={@cell_view.id} />
        <.setup_cell_info />
      </:secondary>
    </.cell_actions>
    <.cell_body>
      <div data-el-info-box>
        <div class="p-3 flex items-center justify-between border border-gray-200 text-sm text-gray-400 font-medium rounded-lg">
          <span>Notebook dependencies and setup</span>
          <.cell_status id={"#{@cell_view.id}-1"} cell_view={@cell_view} />
        </div>
      </div>
      <div data-el-editor-box>
        <div class="relative">
          <.live_component
            module={LivebookWeb.SessionLive.CellEditorComponent}
            id={"#{@cell_view.id}-primary"}
            cell_id={@cell_view.id}
            tag="primary"
            source_view={@cell_view.source_view}
            language="elixir"
            intellisense
          />
          <div class="absolute bottom-2 right-2">
            <.cell_status id={"#{@cell_view.id}-2"} cell_view={@cell_view} />
          </div>
        </div>
        <.evaluation_outputs
          cell_view={@cell_view}
          session_id={@session_id}
          session_pid={@session_pid}
          client_id={@client_id}
        />
      </div>
    </.cell_body>
    """
  end

  defp render_cell(%{cell_view: %{type: :smart}} = assigns) do
    ~H"""
    <.cell_actions>
      <:primary>
        <.cell_evaluation_button
          session_id={@session_id}
          cell_id={@cell_view.id}
          validity={@cell_view.eval.validity}
          status={@cell_view.eval.status}
          reevaluate_automatically={false}
          reevaluates_automatically={@cell_view.eval.reevaluates_automatically}
        />
      </:primary>
      <:secondary>
        <.toggle_source_button />
        <.convert_smart_cell_button cell_id={@cell_view.id} />
        <.cell_link_button cell_id={@cell_view.id} />
        <.move_cell_up_button cell_id={@cell_view.id} />
        <.move_cell_down_button cell_id={@cell_view.id} />
        <.delete_cell_button cell_id={@cell_view.id} />
      </:secondary>
    </.cell_actions>
    <.cell_body>
      <div data-el-ui-box>
        <%= case @cell_view.status do %>
          <% :started -> %>
            <div class={
              "flex #{if(@cell_view.editor && @cell_view.editor.placement == :top, do: "flex-col-reverse", else: "flex-col")}"
            }>
              <.live_component
                module={LivebookWeb.JSViewComponent}
                id={@cell_view.id}
                js_view={@cell_view.js_view}
                session_id={@session_id}
                client_id={@client_id}
              />
              <.live_component
                :if={@cell_view.editor}
                module={LivebookWeb.SessionLive.CellEditorComponent}
                id={"#{@cell_view.id}-secondary"}
                cell_id={@cell_view.id}
                tag="secondary"
                source_view={@cell_view.editor.source_view}
                language={@cell_view.editor.language}
                rounded={@cell_view.editor.placement}
              />
            </div>
          <% :dead -> %>
            <div class="info-box">
              <%= if @installing? do %>
                Waiting for dependency installation to complete...
              <% else %>
                Run the notebook setup to show the contents of this Smart cell.
              <% end %>
            </div>
          <% :down -> %>
            <div class="info-box flex justify-between items-center">
              <span>
                The Smart cell crashed unexpectedly, this is most likely a bug.
              </span>
              <button
                class="button-base button-gray"
                phx-click={JS.push("recover_smart_cell", value: %{cell_id: @cell_view.id})}
              >
                Restart Smart cell
              </button>
            </div>
          <% :starting -> %>
            <div class="delay-200">
              <.content_skeleton empty={false} />
            </div>
        <% end %>
        <div class="flex flex-col items-end space-y-2">
          <div></div>
          <.cell_status id={"#{@cell_view.id}-1"} cell_view={@cell_view} />
        </div>
      </div>
      <div data-el-editor-box>
        <div class="relative">
          <.live_component
            module={LivebookWeb.SessionLive.CellEditorComponent}
            id={"#{@cell_view.id}-primary"}
            cell_id={@cell_view.id}
            tag="primary"
            source_view={@cell_view.source_view}
            language="elixir"
            intellisense
            read_only
          />
          <div class="absolute bottom-2 right-2">
            <.cell_status id={"#{@cell_view.id}-2"} cell_view={@cell_view} />
          </div>
        </div>
      </div>
      <.evaluation_outputs
        cell_view={@cell_view}
        session_id={@session_id}
        session_pid={@session_pid}
        client_id={@client_id}
      />
    </.cell_body>
    """
  end

  defp cell_actions(assigns) do
    assigns =
      assigns
      |> assign_new(:primary, fn -> [] end)
      |> assign_new(:secondary, fn -> [] end)

    ~H"""
    <div class="mb-1 flex items-center justify-between">
      <div class="relative z-20 flex items-center justify-end space-x-2" data-el-actions data-primary>
        <%= render_slot(@primary) %>
      </div>
      <div
        class="relative z-20 flex items-center justify-end space-x-2"
        role="toolbar"
        aria-label="cell actions"
        data-el-actions
      >
        <%= render_slot(@secondary) %>
      </div>
    </div>
    """
  end

  defp cell_body(assigns) do
    ~H"""
    <!-- By setting tabindex we can programmatically focus this element,
         also we actually want to make this element tab-focusable -->
    <div class="flex relative" data-el-cell-body tabindex="0">
      <div class="w-1 h-full rounded-lg absolute top-0 -left-3" data-el-cell-focus-indicator></div>
      <div class="w-full">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp cell_evaluation_button(%{status: :ready} = assigns) do
    ~H"""
    <div class="flex items-center space-x-1">
      <button
        class="text-gray-600 hover:text-gray-800 focus:text-gray-800 flex space-x-1 items-center"
        data-el-queue-cell-evaluation-button
        data-cell-id={@cell_id}
      >
        <%= cond do %>
          <% @reevaluates_automatically -> %>
            <.remix_icon icon="check-line" class="text-xl" />
            <span class="text-sm font-medium">Reevaluates automatically</span>
          <% @validity == :evaluated -> %>
            <.remix_icon icon="play-circle-fill" class="text-xl" />
            <span class="text-sm font-medium">Reevaluate</span>
          <% true -> %>
            <.remix_icon icon="play-circle-fill" class="text-xl" />
            <span class="text-sm font-medium">Evaluate</span>
        <% end %>
      </button>
      <.menu id={"cell-#{@cell_id}-evaluation-menu"} position={:bottom_left} distant>
        <:toggle>
          <button class="flex text-gray-600 hover:text-gray-800 focus:text-gray-800">
            <.remix_icon icon="arrow-down-s-line" class="text-xl" />
          </button>
        </:toggle>
        <.menu_item variant={if(not @reevaluate_automatically, do: :selected, else: :default)}>
          <button
            role="menuitem"
            phx-click={
              JS.push("set_reevaluate_automatically", value: %{value: false, cell_id: @cell_id})
            }
          >
            <.remix_icon icon="check-line" class={if(@reevaluate_automatically, do: "invisible")} />
            <span>Evaluate on demand</span>
          </button>
        </.menu_item>
        <.menu_item variant={if(@reevaluate_automatically, do: :selected, else: :default)}>
          <button
            role="menuitem"
            phx-click={
              JS.push("set_reevaluate_automatically", value: %{value: true, cell_id: @cell_id})
            }
          >
            <.remix_icon icon="check-line" class={if(not @reevaluate_automatically, do: "invisible")} />
            <span>Reevaluate automatically</span>
          </button>
        </.menu_item>
      </.menu>
    </div>
    """
  end

  defp cell_evaluation_button(assigns) do
    ~H"""
    <button
      class="text-gray-600 hover:text-gray-800 focus:text-gray-800 flex space-x-1 items-center"
      phx-click="cancel_cell_evaluation"
      phx-value-cell_id={@cell_id}
    >
      <.remix_icon icon="stop-circle-fill" class="text-xl" />
      <span class="text-sm font-medium">
        Stop
      </span>
    </button>
    """
  end

  defp setup_cell_evaluation_button(%{status: :ready} = assigns) do
    ~H"""
    <div class="flex items-center space-x-1">
      <button
        class="text-gray-600 hover:text-gray-800 focus:text-gray-800 flex space-x-1 items-center"
        data-el-queue-cell-evaluation-button
        data-cell-id={@cell_id}
      >
        <%= if @validity == :fresh do %>
          <.remix_icon icon="play-circle-fill" class="text-xl" />
          <span class="text-sm font-medium">Setup</span>
        <% else %>
          <.remix_icon icon="restart-fill" class="text-xl" />
          <span class="text-sm font-medium">Reconnect and setup</span>
        <% end %>
      </button>
      <%= unless Livebook.Runtime.fixed_dependencies?(@runtime) do %>
        <.menu id="setup-menu" position={:bottom_left} distant>
          <:toggle>
            <button class="flex text-gray-600 hover:text-gray-800 focus:text-gray-800">
              <.remix_icon icon="arrow-down-s-line" class="text-xl" />
            </button>
          </:toggle>
          <.menu_item>
            <button
              role="menuitem"
              data-el-queue-cell-evaluation-button
              data-cell-id={@cell_id}
              data-disable-dependencies-cache
            >
              <.remix_icon icon="play-circle-fill" />
              <span>Setup without cache</span>
            </button>
          </.menu_item>
        </.menu>
      <% end %>
    </div>
    """
  end

  defp setup_cell_evaluation_button(assigns) do
    ~H"""
    <button
      class="text-gray-600 hover:text-gray-800 focus:text-gray-800 flex space-x-1 items-center"
      phx-click="cancel_cell_evaluation"
      phx-value-cell_id={@cell_id}
    >
      <.remix_icon icon="stop-circle-fill" class="text-xl" />
      <span class="text-sm font-medium">
        Stop
      </span>
    </button>
    """
  end

  defp enable_insert_mode_button(assigns) do
    ~H"""
    <span class="tooltip top" data-tooltip="Edit content" data-el-enable-insert-mode-button>
      <button class="icon-button" aria-label="edit content">
        <.remix_icon icon="pencil-line" class="text-xl" />
      </button>
    </span>
    """
  end

  defp toggle_source_button(assigns) do
    ~H"""
    <span class="tooltip top" data-tooltip="Toggle source" data-el-toggle-source-button>
      <button class="icon-button" aria-label="toggle source">
        <.remix_icon icon="code-line" class="text-xl" />
      </button>
    </span>
    """
  end

  defp convert_smart_cell_button(assigns) do
    ~H"""
    <span class="tooltip top" data-tooltip="Convert to Code cell">
      <button
        class="icon-button"
        aria-label="toggle source"
        data-link-package-search
        phx-click={JS.push("convert_smart_cell", value: %{cell_id: @cell_id})}
      >
        <.remix_icon icon="pencil-line" class="text-xl" />
      </button>
    </span>
    """
  end

  defp package_search_button(assigns) do
    ~H"""
    <%= if Livebook.Runtime.fixed_dependencies?(@runtime) do %>
      <span
        class="tooltip top"
        data-tooltip="The current runtime does not support adding dependencies"
      >
        <button class="icon-button" disabled>
          <.remix_icon icon="play-list-add-line" class="text-xl" />
        </button>
      </span>
    <% else %>
      <span class="tooltip top" data-tooltip="Add package (sp)">
        <.link
          patch={~p"/sessions/#{@session_id}/package-search"}
          class="icon-button"
          role="button"
          data-btn-package-search
        >
          <.remix_icon icon="play-list-add-line" class="text-xl" />
        </.link>
      </span>
    <% end %>
    """
  end

  defp cell_link_button(assigns) do
    ~H"""
    <span class="tooltip top" data-tooltip="Link">
      <a href={"#cell-#{@cell_id}"} class="icon-button" role="button" aria-label="link to cell">
        <.remix_icon icon="link" class="text-xl" />
      </a>
    </span>
    """
  end

  def amplify_output_button(assigns) do
    ~H"""
    <span class="tooltip top" data-tooltip="Amplify output" data-el-amplify-outputs-button>
      <button class="icon-button" aria-label="amplify outputs">
        <.remix_icon icon="zoom-in-line" class="text-xl" />
      </button>
    </span>
    """
  end

  defp cell_settings_button(assigns) do
    ~H"""
    <span class="tooltip top" data-tooltip="Cell settings">
      <.link
        patch={~p"/sessions/#{@session_id}/cell-settings/#{@cell_id}"}
        class="icon-button"
        aria-label="cell settings"
        role="button"
      >
        <.remix_icon icon="settings-3-line" class="text-xl" />
      </.link>
    </span>
    """
  end

  defp move_cell_up_button(assigns) do
    ~H"""
    <span class="tooltip top" data-tooltip="Move up">
      <button
        class="icon-button"
        aria-label="move cell up"
        phx-click="move_cell"
        phx-value-cell_id={@cell_id}
        phx-value-offset="-1"
      >
        <.remix_icon icon="arrow-up-s-line" class="text-xl" />
      </button>
    </span>
    """
  end

  defp move_cell_down_button(assigns) do
    ~H"""
    <span class="tooltip top" data-tooltip="Move down">
      <button
        class="icon-button"
        aria-label="move cell down"
        phx-click="move_cell"
        phx-value-cell_id={@cell_id}
        phx-value-offset="1"
      >
        <.remix_icon icon="arrow-down-s-line" class="text-xl" />
      </button>
    </span>
    """
  end

  defp delete_cell_button(assigns) do
    ~H"""
    <span class="tooltip top" data-tooltip="Delete">
      <button
        class="icon-button"
        aria-label="delete cell"
        phx-click={JS.push("delete_cell", value: %{cell_id: @cell_id})}
      >
        <.remix_icon icon="delete-bin-6-line" class="text-xl" />
      </button>
    </span>
    """
  end

  defp setup_cell_info(assigns) do
    ~H"""
    <span
      class="tooltip left"
      data-tooltip={
        ~s'''
        The setup cell includes code that initializes the notebook
        and should run only once. This is the best place to install
        dependencies and set global configuration.\
        '''
      }
    >
      <span class="icon-button">
        <.remix_icon icon="question-line" class="text-xl" />
      </span>
    </span>
    """
  end

  defp evaluation_outputs(assigns) do
    ~H"""
    <div
      class="flex flex-col"
      data-el-outputs-container
      id={"outputs-#{@cell_view.id}-#{@cell_view.eval.outputs_batch_number}"}
      phx-update="append"
    >
      <LivebookWeb.Output.outputs
        outputs={@cell_view.eval.outputs}
        dom_id_map={%{}}
        session_id={@session_id}
        session_pid={@session_pid}
        client_id={@client_id}
        input_values={@cell_view.eval.input_values}
      />
    </div>
    """
  end

  defp empty?(%{source: ""} = _source_view), do: true
  defp empty?(_source_view), do: false

  defp cell_status(%{cell_view: %{eval: %{status: :evaluating}}} = assigns) do
    ~H"""
    <.cell_status_indicator variant={:progressing} change_indicator={true}>
      <span
        class="font-mono"
        id={"#{@id}-cell-timer"}
        phx-hook="Timer"
        phx-update="ignore"
        data-start={DateTime.to_iso8601(@cell_view.eval.evaluation_start)}
      >
      </span>
    </.cell_status_indicator>
    """
  end

  defp cell_status(%{cell_view: %{eval: %{status: :queued}}} = assigns) do
    ~H"""
    <.cell_status_indicator variant={:waiting}>
      Queued
    </.cell_status_indicator>
    """
  end

  defp cell_status(%{cell_view: %{eval: %{validity: :evaluated}}} = assigns) do
    ~H"""
    <.cell_status_indicator
      variant={if(@cell_view.eval.errored, do: :error, else: :success)}
      change_indicator={true}
      tooltip={evaluated_label(@cell_view.eval.evaluation_time_ms)}
    >
      Evaluated
    </.cell_status_indicator>
    """
  end

  defp cell_status(%{cell_view: %{eval: %{validity: :stale}}} = assigns) do
    ~H"""
    <.cell_status_indicator variant={:warning} change_indicator={true}>
      Stale
    </.cell_status_indicator>
    """
  end

  defp cell_status(%{cell_view: %{eval: %{validity: :aborted}}} = assigns) do
    ~H"""
    <.cell_status_indicator variant={:inactive}>
      Aborted
    </.cell_status_indicator>
    """
  end

  defp cell_status(assigns), do: ~H""

  attr :variant, :atom, required: true
  attr :tooltip, :string, default: nil
  attr :change_indicator, :boolean, default: false

  slot :inner_block, required: true

  defp cell_status_indicator(assigns) do
    ~H"""
    <div class={[@tooltip && "tooltip", "bottom distant-medium"]} data-tooltip={@tooltip}>
      <div class="flex items-center space-x-1">
        <div class="flex text-xs text-gray-400" data-el-cell-status>
          <%= render_slot(@inner_block) %>
          <span :if={@change_indicator} data-el-change-indicator>*</span>
        </div>
        <.status_indicator variant={@variant} />
      </div>
    </div>
    """
  end

  defp evaluated_label(time_ms) when is_integer(time_ms) do
    evaluation_time =
      if time_ms > 100 do
        seconds = time_ms |> Kernel./(1000) |> Float.floor(1)
        "#{seconds}s"
      else
        "#{time_ms}ms"
      end

    "Took " <> evaluation_time
  end

  defp evaluated_label(_time_ms), do: nil

  defp smart_cell_js_view_ref(%{type: :smart, status: :started, js_view: %{ref: ref}}), do: ref
  defp smart_cell_js_view_ref(_cell_view), do: nil
end
