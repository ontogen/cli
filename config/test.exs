import Config

config :ontogen,
  system_config_path: Path.expand("test/data/config/tmp_system_config.ttl"),
  global_config_path: Path.expand("test/data/config/global_config.ttl"),
  create_repo_id_file: false
