# frozen_string_literal: true
# Why do the above though win windows? Check in Perf testing 

module OMS
    # kaveesh: These error codes are from the base OMS Agent for linux and for consistency I'm keeping them as is because the numbers don't really make a difference to us.
    # https://github.com/microsoft/OMS-Agent-for-Linux/blob/824c40889ba0c0a819a97184846c4abef30f474c/source/code/plugins/agent_common.rb#L33
    # Error codes and categories:
    # User configuration/parameters:
    INVALID_OPTION_PROVIDED = 2
    NON_PRIVELEGED_USER_ERROR_CODE = 3
    # System configuration:
    MISSING_CONFIG_FILE = 4
    MISSING_CONFIG = 5
    MISSING_CERTS = 6
    # Service/network-related:
    HTTP_NON_200 = 7
    ERROR_SENDING_HTTP = 8
    ERROR_EXTRACTING_ATTRIBUTES = 9
    MISSING_CERT_UPDATE_ENDPOINT = 10
    # Internal errors:
    ERROR_GENERATING_CERTS = 11
    ERROR_WRITING_TO_FILE = 12
    ERROR_RENEWING_CERTS = 13
    ERROR_EXECUTING_RENEW_CERTS_COMMAND = 14
    
    class CaseSensitiveString < String
        def downcase
          self
        end
        def capitalize
          self
        end
        def to_s
          self
        end
    end

    class StrongTypedClass
        def self.strongtyped_accessor(name, type)
          # setter
          self.class_eval("def #{name}=(value);
          if !value.is_a? #{type} and !value.nil?
              raise ArgumentError, \"Invalid data type. #{name} should be type #{type}\"
          end
          @#{name}=value
          end")
          # getter
          self.class_eval("def #{name};@#{name};end")
        end
        
        def self.strongtyped_arch(name)
          # setter
          self.class_eval("def #{name}=(value);
          if (value != 'x64' && value != 'x86')
              raise ArgumentError, \"Invalid data for ProcessorArchitecture.\"
          end
          @#{name}=value
          end")
        end
    end
end