defmodule KodaMarkdownWeb.Router do
  use KodaMarkdownWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {KodaMarkdownWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug(KodaMarkdownWeb.PlugRedirectTrailingSlash, :without)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: KodaMarkdownWeb.Telemetry
    end
  end

  scope "/", KodaMarkdownWeb do
    pipe_through :browser

    live "/", Live.Index, :index
    live "/*slug", Live.Content, :show, as: :content
  end

  # Other scopes may use custom stacks.
  # scope "/api", KodaMarkdownWeb do
  #   pipe_through :api
  # end
end
