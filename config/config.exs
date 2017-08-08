# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :collab,
  ecto_repos: [Collab.Repo]

# Configures the endpoint
config :collab, CollabWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "6cHMh6n0p+CJN4nSfVca8r9Wa4lHHJMJMppRxxV263KaWhGEt7DqqddrzSKJEzrr",
  render_errors: [view: CollabWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Collab.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
