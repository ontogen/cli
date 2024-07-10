import Config

# Ontogen config ####################################################

config :ontogen,
  env: Mix.env(),
  allow_configless_mode: true,
  config_load_paths: [:local],
  # CAUTION: These paths also determine the paths of the config files created with the init command
  local_config_path: ".ontogen/config",
  salt_path: ".ontogen/.salts"

config :ontogen,
  grax_id_spec: Ontogen.IdSpec

# RDF config ########################################################

config :rdf,
  use_standard_prefixes: false

# SPARQL.Client config ##############################################

config :sparql_client,
  protocol_version: "1.1",
  update_request_method: :direct

config :tesla, adapter: Tesla.Adapter.Hackney

import_config "#{Mix.env()}.exs"
