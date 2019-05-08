#!/usr/local/bin/ruby
# frozen_string_literal: true

require_relative "tomlrb"

# Setting default values which will be used in case they are not set in the configmap or if configmap doesnt exist
collectStdoutLogs = true
stdoutExcludeNamespaces = []
collectStdErrLogs = true
stderrExcludeNamespaces = []
collectClusterEnvVariables = true

begin
  # Check to see if config map is created
  if (File.file?("/etc/config/settings/omsagent-settings"))
    parsedconfig = Tomlrb.load_file("/etc/config/settings/omsagent-settings", symbolize_keys: true)
  end
rescue => errorStr
  puts "Exception while parsing toml config file: #{errorStr}"
end

file = File.open("config_env_var.txt", "w")

if !file.nil?
  begin
    if !parsedconfig.nil? && !parsedconfig[:log_collection_settings].nil?
      #Get stdout log config settings
      if !parsedconfig[:log_collection_settings][:stdout].nil? && !parsedconfig[:log_collection_settings][:stdout][:enabled].nil?
        collectStdoutLogs = parsedconfig[:log_collection_settings][:stdout][:enabled]
        #file.write("export AZMON_COLLECT_STDOUT_LOGS=#{collectStdoutLogs}\n")
        if parsedconfig[:log_collection_settings][:stdout][:enabled] && !parsedconfig[:log_collection_settings][:stdout][:exclude_namespaces].nil?
          stdoutExcludeNamespaces = parsedconfig[:log_collection_settings][:stdout][:exclude_namespaces]
          #file.write("export AZMON_STDOUT_EXCLUDED_NAMESPACES=#{parsedconfig[:log_collection_settings][:stdout][:exclude_namespaces]}\n")
        end
      end
      #Get stderr log config settings
      if !parsedconfig[:log_collection_settings][:stderr].nil? && !parsedconfig[:log_collection_settings][:stderr][:enabled].nil?
        collectStdErrLogs = parsedconfig[:log_collection_settings][:stderr][:enabled]
        #file.write("export AZMON_COLLECT_STDERR_LOGS=#{parsedconfig[:log_collection_settings][:stderr][:enabled]}\n")
        if parsedconfig[:log_collection_settings][:stderr][:enabled] && !parsedconfig[:log_collection_settings][:stderr][:exclude_namespaces].nil?
          stderrExcludeNamespaces = parsedconfig[:log_collection_settings][:stderr][:exclude_namespaces]
          #file.write("export AZMON_STDERR_EXCLUDED_NAMESPACES=#{parsedconfig[:log_collection_settings][:stderr][:exclude_namespaces]}\n")
        end
      end
      #Get environment variables log config settings
      if !parsedconfig[:log_collection_settings][:env_var].nil? && !parsedconfig[:log_collection_settings][:env_var][:enabled].nil?
        collectClusterEnvVariables = parsedconfig[:log_collection_settings][:env_var][:enabled]
        #file.write("export AZMON_COLLECT_ENV_VAR=#{parsedconfig[:log_collection_settings][:env_var][:enabled]}\n")
      end
      # Close file after writing all environment variables
      file.close
    end
  rescue => errorStr
    puts "Exception in reading config file, using defaults"
  end
else
  puts "Exception while opening file for writing config environment variables"
end
