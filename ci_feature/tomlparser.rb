#!/usr/local/bin/ruby
# frozen_string_literal: true

require_relative "tomlrb"

begin
  parsedconfig = Tomlrb.load_file("config.toml", symbolize_keys: true)
rescue => errorStr
  puts "Exception while parsing toml config file: #{errorStr}"
end

file = File.open("config_env_var.txt", "w")

if !file.nil?
  begin
    if !parsedconfig.nil? && !parsedconfig[:log_collection_settings].nil?
      #Get stdout log config settings
      if !parsedconfig[:log_collection_settings][:stdout].nil? && !parsedconfig[:log_collection_settings][:stdout][:enabled].nil?
        file.write("export AZMON_COLLECT_STDOUT_LOGS=#{parsedconfig[:log_collection_settings][:stdout][:enabled]}\n")
        puts "Using config map setting for stdout log collection"
        if parsedconfig[:log_collection_settings][:stdout][:enabled] && !parsedconfig[:log_collection_settings][:stdout][:exclude_namespaces].nil?
          file.write("export AZMON_STDOUT_EXCLUDED_NAMESPACES=#{parsedconfig[:log_collection_settings][:stdout][:exclude_namespaces]}\n")
          puts "Using config map setting for stdout log collection to exclude namespace"
        end
      end
      #Get stderr log config settings
      if !parsedconfig[:log_collection_settings][:stderr].nil? && !parsedconfig[:log_collection_settings][:stderr][:enabled].nil?
        file.write("export AZMON_COLLECT_STDERR_LOGS=#{parsedconfig[:log_collection_settings][:stderr][:enabled]}\n")
        puts "Using config map setting for stderr log collection"
        if parsedconfig[:log_collection_settings][:stderr][:enabled] && !parsedconfig[:log_collection_settings][:stderr][:exclude_namespaces].nil?
          file.write("export AZMON_STDERR_EXCLUDED_NAMESPACES=#{parsedconfig[:log_collection_settings][:stderr][:exclude_namespaces]}\n")
          puts "Using config map setting for stderr log collection to exclude namespace"
        end
      end
      #Get environment variables log config settings
      if !parsedconfig[:log_collection_settings][:env_var].nil? && !parsedconfig[:log_collection_settings][:env_var][:enabled].nil?
        file.write("export AZMON_CLUSTER_COLLECT_ENV_VAR=#{parsedconfig[:log_collection_settings][:env_var][:enabled]}\n")
        puts "Using config map setting for cluster level environment variable collection"
      end
      # Close file after writing all environment variables
      file.close
    end
  rescue => errorStr
    puts "Exception in reading config file and key value pairs to file"
  end
else
  puts "Exception while opening file for writing config environment variables"
end
