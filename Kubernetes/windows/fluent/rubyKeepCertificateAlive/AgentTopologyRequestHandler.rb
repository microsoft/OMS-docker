# frozen_string_literal: true
# Why do the above though win windows? Check in Perf testing 

module OMS

    require_relative 'omscommon'

    class AgentTopologyRequestOperatingSystem < StrongTypedClass
        strongtyped_accessor :Name, String
        strongtyped_accessor :Manufacturer, String
        strongtyped_arch     :ProcessorArchitecture
        strongtyped_accessor :Version, String
        strongtyped_accessor :InContainer, String
        strongtyped_accessor :InContainerVersion, String
        strongtyped_accessor :IsAKSEnvironment, String
        strongtyped_accessor :K8SVersion, String
      end

    class AgentTopologyRequest < StrongTypedClass
        strongtyped_accessor :FullyQualfiedDomainName, String
        strongtyped_accessor :EntityTypeId, String
        strongtyped_accessor :AuthenticationCertificate, String
        strongtyped_accessor :OperatingSystem, AgentTopologyRequestOperatingSystem
    end

    class AgentTopologyRequestHandler
        require 'gyoku'

        def initialize
            puts "initializing AgentTopologyRequestHandler..."
        end

        def obj_to_hash(obj)
            hash = {}
            obj.instance_variables.each { |var|
            val = obj.instance_variable_get(var)
                next if val.nil?
                if val.is_a? StrongTypedClass
                    hash[var.to_s.delete("@")] = obj_to_hash(val)
                else
                    hash[var.to_s.delete("@")] = val
                end
            }
            return hash
        end

        def handle_request(entity_type_id, auth_cert)
            topology_request = AgentTopologyRequest.new
            topology_request.FullyQualfiedDomainName = `hostname`#evaluate_fqdn()
            topology_request.EntityTypeId = entity_type_id
            topology_request.AuthenticationCertificate = auth_cert
            body_heartbeat = "<?xml version=\"1.0\"?>\n"
            body_heartbeat.concat(Gyoku.xml({ "AgentTopologyRequest" => {:content! => obj_to_hash(topology_request), \
:'@xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance", :'@xmlns:xsd' => "http://www.w3.org/2001/XMLSchema", \
:@xmlns => "http://schemas.microsoft.com/WorkloadMonitoring/HealthServiceProtocol/2014/09/"}}))
                
            return body_heartbeat        
        end
    end
end