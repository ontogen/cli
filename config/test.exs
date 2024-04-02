import Config

config :ontogen,
  system_config_path: Path.expand("test/data/config/tmp_system_config.ttl"),
  global_config_path: Path.expand("test/data/config/global_config.ttl"),
  # CAUTION: The path also determines the path of the config file created with the init command
  local_config_path: ".ontogen/test_config.ttl",
  create_repo_id_file: false
