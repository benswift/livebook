defmodule LivebookWeb.SessionControllerTest do
  use LivebookWeb.ConnCase, async: true

  alias Livebook.{Sessions, Session, Notebook, FileSystem}

  describe "show_image" do
    test "returns not found when the given session does not exist", %{conn: conn} do
      id = Livebook.Utils.random_node_aware_id()
      conn = get(conn, ~p"/sessions/#{id}/images/image.jpg")

      assert conn.status == 404
      assert conn.resp_body == "Not found"
    end

    test "returns not found when the given image does not exist", %{conn: conn} do
      {:ok, session} = Sessions.create_session()

      conn = get(conn, ~p"/sessions/#{session.id}/images/nonexistent.jpg")

      assert conn.status == 404
      assert conn.resp_body == "No such file or directory"

      Session.close(session.pid)
    end

    test "returns the image when it does exist", %{conn: conn} do
      {:ok, session} = Sessions.create_session()
      %{images_dir: images_dir} = session
      :ok = FileSystem.File.resolve(images_dir, "test.jpg") |> FileSystem.File.write("")

      conn = get(conn, ~p"/sessions/#{session.id}/images/test.jpg")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["image/jpeg"]

      Session.close(session.pid)
    end
  end

  describe "download_source" do
    test "returns not found when the given session does not exist", %{conn: conn} do
      id = Livebook.Utils.random_node_aware_id()
      conn = get(conn, ~p"/sessions/#{id}/export/download/livemd")

      assert conn.status == 404
      assert conn.resp_body == "Not found"
    end

    test "returns bad request when given an invalid format", %{conn: conn} do
      {:ok, session} = Sessions.create_session()

      conn = get(conn, ~p"/sessions/#{session.id}/export/download/invalid")

      assert conn.status == 400
      assert conn.resp_body == "Invalid format, supported formats: livemd, exs"

      Session.close(session.pid)
    end

    test "handles live markdown notebook source", %{conn: conn} do
      {:ok, session} = Sessions.create_session()

      conn = get(conn, ~p"/sessions/#{session.id}/export/download/livemd")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain"]

      assert conn.resp_body == """
             # Untitled notebook

             ## Section

             ```elixir

             ```
             """

      Session.close(session.pid)
    end

    test "includes output in markdown when include_outputs parameter is set", %{conn: conn} do
      notebook = %{
        Notebook.new()
        | name: "My Notebook",
          sections: [
            %{
              Notebook.Section.new()
              | name: "Section 1",
                cells: [
                  %{
                    Notebook.Cell.new(:code)
                    | source: """
                      IO.puts("hey")\
                      """,
                      outputs: [{0, {:stdout, "hey"}}]
                  }
                ]
            }
          ]
      }

      {:ok, session} = Sessions.create_session(notebook: notebook)

      conn = get(conn, ~p"/sessions/#{session.id}/export/download/livemd?include_outputs=true")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain"]

      assert conn.resp_body == """
             # My Notebook

             ## Section 1

             ```elixir
             IO.puts("hey")
             ```

             <!-- livebook:{"output":true} -->

             ```
             hey
             ```
             """

      Session.close(session.pid)
    end

    test "handles elixir notebook source", %{conn: conn} do
      {:ok, session} = Sessions.create_session()

      conn = get(conn, ~p"/sessions/#{session.id}/export/download/exs")

      assert conn.status == 200
      assert get_resp_header(conn, "content-type") == ["text/plain"]

      assert conn.resp_body == """
             # Run as: iex --dot-iex path/to/notebook.exs

             # Title: Untitled notebook

             # ── Section ──
             """

      Session.close(session.pid)
    end
  end

  describe "show_asset" do
    test "fetches assets and redirects to the session-less path", %{conn: conn} do
      %{notebook: notebook, hash: hash} = notebook_with_js_output()

      conn = start_session_and_request_asset(conn, notebook, hash)

      assert redirected_to(conn, 301) == ~p"/public/sessions/assets/#{hash}/main.js"

      {:ok, asset_path} = Session.local_asset_path(hash, "main.js")
      assert File.exists?(asset_path)
    end

    test "fetches assets and redirects even on empty asset directories", %{conn: conn} do
      %{notebook: notebook, hash: hash} = notebook_with_js_output()
      assets_path = Session.local_assets_path(hash)
      File.mkdir_p!(assets_path)

      conn = start_session_and_request_asset(conn, notebook, hash)

      assert redirected_to(conn, 301) == ~p"/public/sessions/assets/#{hash}/main.js"

      assert File.exists?(Path.join(assets_path, "main.js"))
    end

    test "skips the session if assets are in cache", %{conn: conn} do
      %{notebook: notebook, hash: hash} = notebook_with_js_output()
      # Fetch the assets for the first time
      start_session_and_request_asset(conn, notebook, hash)

      # Use nonexistent session, so any communication would fail
      random_session_id = Livebook.Utils.random_node_aware_id()

      conn = get(conn, ~p"/public/sessions/#{random_session_id}/assets/#{hash}/main.js")

      assert redirected_to(conn, 301) == ~p"/public/sessions/assets/#{hash}/main.js"
    end
  end

  describe "show_cached_asset" do
    test "returns not found when no matching assets are in the cache", %{conn: conn} do
      %{notebook: _notebook, hash: hash} = notebook_with_js_output()

      conn = get(conn, ~p"/public/sessions/assets/#{hash}/main.js")

      assert conn.status == 404
      assert conn.resp_body == "Not found"
    end

    test "returns the requests asset if available in cache", %{conn: conn} do
      %{notebook: notebook, hash: hash} = notebook_with_js_output()
      # Fetch the assets for the first time
      start_session_and_request_asset(conn, notebook, hash)

      conn = get(conn, ~p"/public/sessions/assets/#{hash}/main.js")

      assert conn.status == 200
      assert "export function init(" <> _ = conn.resp_body
    end

    test "supports gzip compression", %{conn: conn} do
      %{notebook: notebook, hash: hash} = notebook_with_js_output()

      start_session_and_request_asset(conn, notebook, hash)

      conn =
        conn
        |> put_req_header("accept-encoding", "gzip")
        |> get(~p"/public/sessions/assets/#{hash}/main.js")

      assert conn.status == 200
      assert "export function init(" <> _ = :zlib.gunzip(conn.resp_body)
    end
  end

  defp start_session_and_request_asset(conn, notebook, hash) do
    {:ok, session} = Sessions.create_session(notebook: notebook)
    # We need runtime in place to actually copy the archive
    {:ok, runtime} = Livebook.Runtime.Embedded.new() |> Livebook.Runtime.connect()
    Session.set_runtime(session.pid, runtime)

    conn = get(conn, ~p"/public/sessions/#{session.id}/assets/#{hash}/main.js")

    Session.close(session.pid)

    conn
  end

  defp notebook_with_js_output() do
    archive_path = Path.expand("../../support/assets.tar.gz", __DIR__)
    hash = "test-" <> Livebook.Utils.random_id()
    assets_info = %{archive_path: archive_path, hash: hash, js_path: "main.js"}
    output = {:js, %{js_view: %{assets: assets_info}}}

    notebook = %{
      Notebook.new()
      | sections: [
          %{
            Notebook.Section.new()
            | cells: [%{Notebook.Cell.new(:code) | outputs: [{0, output}]}]
          }
        ]
    }

    %{notebook: notebook, hash: hash}
  end
end
