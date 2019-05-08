#!/usr/local/bin/ruby
# frozen_string_literal: true

require_relative "tomlrb"

@configMapMountPath = "/etc/config/settings/omsagent-settings"
# Setting default values which will be used in case they are not set in the configmap or if configmap doesnt exist
@collectStdoutLogs = true
@stdoutExcludeNamespaces = ["kube-system"]
@collectStdErrLogs = true
@stderrExcludeNamespaces = ["kube-system"]
@collectClusterEnvVariables = true

# Use parser to parse the configmap toml file to a ruby structure
def parseConfigMap
  begin
    # Check to see if config map is created
    if (File.file?(@configMapMountPath))
      puts "config map for settings mounted, parsing values"
      parsedConfig = Tomlrb.load_file(@configMapMountPath, symbolize_keys: true)
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
  if !parsedconfig.nil? && !parsedconfig[:log_collection_settings].nil?
    #Get stdout log config settings
    begin
      if !parsedconfig[:log_collection_settings][:stdout].nil? && !parsedconfig[:log_collection_settings][:stdout][:enabled].nil?
        @collectStdoutLogs = parsedconfig[:log_collection_settings][:stdout][:enabled]
        #file.write("export AZMON_COLLECT_STDOUT_LOGS=#{collectStdoutLogs}\n")
        puts "Using config map setting for stdout log collection"
        if parsedconfig[:log_collection_settings][:stdout][:enabled] && !parsedconfig[:log_collection_settings][:stdout][:exclude_namespaces].nil?
          @stdoutExcludeNamespaces = parsedconfig[:log_collection_settings][:stdout][:exclude_namespaces]
          #file.write("export AZMON_STDOUT_EXCLUDED_NAMESPACES=#{parsedconfig[:log_collection_settings][:stdout][:exclude_namespaces]}\n")
          puts "Using config map setting for stdout log collection to exclude namespace"
        end
      end
    rescue => errorStr
      puts "Exception while reading config settings for stdout log collection - #{errorStr}, using defaults"
    end

    #Get stderr log config settings
    begin
      if !parsedconfig[:log_collection_settings][:stderr].nil? && !parsedconfig[:log_collection_settings][:stderr][:enabled].nil?
        @collectStdErrLogs = parsedconfig[:log_collection_settings][:stderr][:enabled]
        puts "Using config map setting for stderr log collection"
        if parsedconfig[:log_collection_settings][:stderr][:enabled] && !parsedconfig[:log_collection_settings][:stderr][:exclude_namespaces].nil?
          @stderrExcludeNamespaces = parsedconfig[:log_collection_settings][:stderr][:exclude_namespaces]
          puts "Using config map setting for stderr log collection to exclude namespace"
        end
      end
    rescue => errorStr
      puts "Exception while reading config settings for stderr log collection - #{errorStr}, using defaults"
    end

    #Get environment variables log config settings
    begin
      if !parsedconfig[:log_collection_settings][:env_var].nil? && !parsedconfig[:log_collection_settings][:env_var][:enabled].nil?
        @collectClusterEnvVariables = parsedconfig[:log_collection_settings][:env_var][:enabled]
        puts "Using config map setting for cluster level environment variable collection"
      end
    rescue => errorStr
      puts "Exception while reading config settings for cluster level environment variable collection - #{errorStr}, using defaults"
    end
    # Close file after writing all environment variables
    #file.close
  end
end

configMapSettings = parseConfigMap
if !configMapSettings.nil?
  populateSettingValuesFromConfigMap(configMapSettings)
end

file = File.open("config_env_var.txt", "w")

if !file.nil?
  file.write("export AZMON_COLLECT_STDOUT_LOGS=#{@collectStdoutLogs}\n")
  # This will be used in td-agent-bit.conf file to filter out logs
  if (!@collectStdoutLogs && !@collectStderrLogs)
    file.write("export LOG_EXCLUSION_REGEX_PATTERN=\"stderr|stdout\"\n")
  elsif !@collectStdoutLogs
    file.write("export LOG_EXCLUSION_REGEX_PATTERN=\"stdout\"\n")
  else
    file.write("export LOG_EXCLUSION_REGEX_PATTERN=\"stderr\"\n")
  end

  file.write("export AZMON_STDOUT_EXCLUDED_NAMESPACES=#{@stdoutExcludeNamespaces}\n")
  file.write("export AZMON_COLLECT_STDERR_LOGS=#{@collectStderrLogs}\n")
  file.write("export AZMON_STDERR_EXCLUDED_NAMESPACES=#{@stderrExcludeNamespaces}\n")
  file.write("export AZMON_CLUSTER_COLLECT_ENV_VAR=#{@collectClusterEnvVariables}\n")
else
  puts "Exception while opening file for writing config environment variables"
end
