#!/usr/local/bin/ruby
# frozen_string_literal: true

require_relative "tomlrb"

@configMapMountPath = "/etc/config/settings/omsagent-settings"
# Setting default values which will be used in case they are not set in the configmap or if configmap doesnt exist
@collectStdoutLogs = true
@stdoutExcludeNamespaces = []
@collectStdErrLogs = true
@stderrExcludeNamespaces = []
@collectClusterEnvVariables = true
@logTailPath = "/var/log/containers/*.log"

# Use parser to parse the configmap toml file to a ruby structure
def parseConfigMap
  begin
    # Check to see if config map is created
    if (File.file?(@configMapMountPath))
      puts "config map for settings mounted, parsing values"
      parsedConfig = Tomlrb.load_file(@configMapMountPath, symbolize_keys: true)
      puts "Successfully parsed mounted config map"
      return parsedConfig
    else
      puts "config map for settings not mounted, using defaults"
      return nil
    end
  rescue => errorStr
    puts "Exception while parsing toml config file: #{errorStr}"
    return nil
  end
end

# Use the ruby structure created after config parsing to set the right values to be used as environment variables
def populateSettingValuesFromConfigMap(parsedConfig)
  if !parsedConfig.nil? && !parsedConfig[:log_collection_settings].nil?
    #Get stdout log config settings
    begin
      if !parsedConfig[:log_collection_settings][:stdout].nil? && !parsedConfig[:log_collection_settings][:stdout][:enabled].nil?
        @collectStdoutLogs = parsedConfig[:log_collection_settings][:stdout][:enabled]
        puts "Using config map setting for stdout log collection"
        stdoutNamespaces = parsedConfig[:log_collection_settings][:stdout][:exclude_namespaces]
        if parsedConfig[:log_collection_settings][:stdout][:enabled] && !stdoutNamespaces.nil?
          stdoutNamespaces.each do |namespace|
            @stdoutExcludeNamespaces.push(namespace)
          end
          puts "Using config map setting for stdout log collection to exclude namespace"
        end
      end
    rescue => errorStr
      puts "Exception while reading config settings for stdout log collection - #{errorStr}, using defaults"
    end

    #Get stderr log config settings
    begin
      if !parsedConfig[:log_collection_settings][:stderr].nil? && !parsedConfig[:log_collection_settings][:stderr][:enabled].nil?
        @collectStdErrLogs = parsedConfig[:log_collection_settings][:stderr][:enabled]
        puts "Using config map setting for stderr log collection"
        stderrNamespaces = parsedConfig[:log_collection_settings][:stderr][:exclude_namespaces]
        if parsedConfig[:log_collection_settings][:stderr][:enabled] && !stderrNamespaces.nil?
          stdoutNamespaces.each do |namespace|
            @stderrExcludeNamespaces.push(namespace)
          end
          puts "Using config map setting for stderr log collection to exclude namespace"
        end
      end
    rescue => errorStr
      puts "Exception while reading config settings for stderr log collection - #{errorStr}, using defaults"
    end

    #Get environment variables log config settings
    begin
      if !parsedConfig[:log_collection_settings][:env_var].nil? && !parsedConfig[:log_collection_settings][:env_var][:enabled].nil?
        @collectClusterEnvVariables = parsedConfig[:log_collection_settings][:env_var][:enabled]
        puts "Using config map setting for cluster level environment variable collection"
      end
    rescue => errorStr
      puts "Exception while reading config settings for cluster level environment variable collection - #{errorStr}, using defaults"
    end
  end
end

configMapSettings = parseConfigMap
if !configMapSettings.nil?
  populateSettingValuesFromConfigMap(configMapSettings)
end

# Write the settings to file, so that they can be set as environment variables
file = File.open("config_env_var.txt", "w")

if !file.nil?
  # This will be used in td-agent-bit.conf file to filter out logs
  if (!@collectStdoutLogs && !@collectStderrLogs)
    #Stop log tailing completely
    @logTailPath = "/opt/nolog*.log"
  elsif !@collectStdoutLogs
    file.write("export AZMON_LOG_EXCLUSION_REGEX_PATTERN=\"stdout\"\n")
  elsif !@collectStderrLogs
    file.write("export AZMON_LOG_EXCLUSION_REGEX_PATTERN=\"stderr\"\n")
  end
  #   file.write("export AZMON_COLLECT_STDOUT_LOGS=#{@collectStdoutLogs}\n")
  file.write("export AZMON_LOG_TAIL_PATH=#{@logTailPath}\n")
  file.write("export AZMON_STDOUT_EXCLUDED_NAMESPACES=#{@stdoutExcludeNamespaces}\n")
  #   file.write("export AZMON_COLLECT_STDERR_LOGS=#{@collectStderrLogs}\n")
  file.write("export AZMON_STDERR_EXCLUDED_NAMESPACES=#{@stderrExcludeNamespaces}\n")
  file.write("export AZMON_CLUSTER_COLLECT_ENV_VAR=#{@collectClusterEnvVariables}\n")
  # Close file after writing all environment variables
  file.close
else
  puts "Exception while opening file for writing config environment variables"
end
