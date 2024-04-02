import Config

# Ontogen config ####################################################

config :ontogen,
  # CAUTION: These paths also determine the paths of the config and repo id file created with the init command
  local_config_path: ".ontogen/config.ttl",
  repo_id_file: ".ontogen/repo",
  allow_configless_mode: true

config :ontogen,
  grax_id_spec: Ontogen.IdSpec

# SPARQL.Client config ##############################################

config :sparql_client,
  protocol_version: "1.1",
  update_request_method: :direct

config :tesla, adapter: Tesla.Adapter.Hackney

import_config "#{Mix.env()}.exs"
