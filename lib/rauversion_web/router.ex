defmodule RauversionWeb.Router do
  use RauversionWeb, :router

  import RauversionWeb.UserAuth

  import Plug.BasicAuth

  pipeline :bauth do
    plug :basic_auth, username: "rau", password: "raurocks"
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {RauversionWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :browser_embed do
    plug :accepts, ["html"]
    # plug :fetch_session
    # plug :fetch_live_flash
    plug :put_secure_browser_headers
    plug :put_new_layout, {RauversionWeb.LayoutView, :embed}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RauversionWeb do
    pipe_through :browser
    get "/", PageController, :index
  end

  scope "/", RauversionWeb do
    pipe_through :browser_embed
    get "/embed/:track_id", EmbedController, :show
    get "/embed/:track_id/private", EmbedController, :private

    get "/embed/sets/:playlist_id", EmbedController, :show_playlist
    get "/embed/sets/:playlist_id/private", EmbedController, :private_playlist
  end

  # Other scopes may use custom stacks.
  # scope "/api", RauversionWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test, :prod] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      pipe_through :bauth
      live_dashboard "/dashboard", metrics: RauversionWeb.Telemetry, ecto_repos: [Rauversion.Repo]
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", RauversionWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", RauversionWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/users/settings", UserSettingsLive.Index, :profile
    live "/users/settings/email", UserSettingsLive.Index, :email
    live "/users/settings/security", UserSettingsLive.Index, :security

    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    live "/tracks/new", TrackLive.New, :new
    live "/tracks/:id/edit", TrackLive.Index, :edit

    live "/tracks/:id/show/edit", TrackLive.Show, :edit

    live "/reposts/new", RepostLive.Index, :new
    live "/reposts/:id/edit", RepostLive.Index, :edit

    live "/reposts/:id/show/edit", RepostLive.Show, :edit

    live "/playlists/new", PlaylistLive.Index, :new
    live "/playlists/:id/edit", PlaylistLive.Index, :edit
    live "/playlists/:id/show/edit", PlaylistLive.Show, :edit
  end

  scope "/", RauversionWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update

    live "/tracks", TrackLive.Index, :index
    live "/tracks/:id", TrackLive.Show, :show
    live "/tracks/:id/private", TrackLive.Show, :private
    live "/reposts", RepostLive.Index, :index
    live "/reposts/:id", RepostLive.Show, :show
    live "/playlists", PlaylistLive.Index, :index
    live "/playlists/:id", PlaylistLive.Show, :show
    live "/playlists/:id/private", PlaylistLive.Show, :private

    get(
      "/active_storage/blobs/redirect/:signed_id/*filename",
      ActiveStorage.Blobs.RedirectController,
      :show
    )

    get(
      "/active_storage/blobs/proxy/:signed_id/*filename",
      ActiveStorage.Blobs.ProxyController,
      :show
    )

    # get("/blobs/:signed_id/*filename", ActiveStorage.Blob.ProxyController, :show)

    # get "/blobs/redirect/:signed_id/*filename" => "active_storage/blobs/redirect#show", as: :rails_service_blob
    # get "/blobs/proxy/:signed_id/*filename" => "active_storage/blobs/proxy#show", as: :rails_service_blob_proxy
    # get "/blobs/:signed_id/*filename" => "active_storage/blobs/redirect#show"

    get(
      "/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename",
      ActiveStorage.Representations.RedirectController,
      :show
    )

    get(
      "/representations/proxy/:signed_blob_id/:variation_key/*filename",
      ActiveStorage.Representations.ProxyController,
      :show
    )

    # get "/representations/redirect/:signed_blob_id/:variation_key/*filename" => "active_storage/representations/redirect#show", as: :rails_blob_representation
    # get "/representations/proxy/:signed_blob_id/:variation_key/*filename" => "active_storage/representations/proxy#show", as: :rails_blob_representation_proxy
    # get "/representations/:signed_blob_id/:variation_key/*filename" => "active_storage/representations/redirect#show"

    get(
      "/active_storage/disk/:encoded_key/*filename",
      ActiveStorage.DiskController,
      :show
    )

    # get  "/disk/:encoded_key/*filename" => "active_storage/disk#show", as: :rails_disk_service
    # put  "/disk/:encoded_token" => "active_storage/disk#update", as: :update_rails_disk_service
    # post "/direct_uploads" => "active_storage/direct_uploads#create", as: :rails_direct_uploads

    # get "/:username", ProfileController, :show
    live "/:username", ProfileLive.Index, :index
    live "/:username/followers", FollowsLive.Index, :followers
    live "/:username/following", FollowsLive.Index, :followings
    live "/:username/comments", FollowsLive.Index, :comments
    live "/:username/likes", FollowsLive.Index, :likes
    live "/:username/tracks/all", ProfileLive.Index, :tracks_all
    live "/:username/tracks/reposts", ProfileLive.Index, :reposts
    live "/:username/tracks/albums", ProfileLive.Index, :albums
    live "/:username/tracks/playlists", ProfileLive.Index, :playlists
    live "/:username/tracks/popular", ProfileLive.Index, :popular
    live "/:username/insights", ProfileLive.Index, :insights
  end
end
