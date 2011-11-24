require 'resolv'
module DNSServer
  class ConnectionUDP < EventMachine::Connection
    def initialize(options)
      @options = options
      # this function gets extra arguments
      @logger = @options[:logger]
      @logger.info "DNS Server ready"
    end

    def build_response_for(query)
      # Initialize response
      response        = Resolv::DNS::Message::new(query.id)
      response.qr     = 1             # 0 = Query, 1 = Response
      response.opcode = query.opcode  # Type of Query; copy from query
      response.aa     = 1             # Is this an authoritative response: 0 = No, 1 = Yes
      response.rd     = query.rd      # Is Recursion Desired, copied from query
      response.ra     = 0             # Does name server support recursion: 0 = No, 1 = Yes
      response.rcode  = 0             # Response code: 0 = No errors
      response
    end

    def receive_data(data)
      query = Resolv::DNS::Message::decode(data)
      response = build_response_for query
      query.each_question do |question, typeclass| # There may be multiple questions per query
        name = question.to_s # The domain name looked for in the query.
        record_type = typeclass.name.split("::").last # For example "A", "MX"
        @logger.info "query: #{name} (#{record_type})"
        record = @options[:resolver].call(name, record_type)
        # Magic has to happen in this part (checking the domain name)
        unless record.nil?
          # Add answer to this question
          response.add_answer(name + ".", record[:ttl], typeclass.new(record[:ip])) # Parameters are: hostname, ttl, IP address
        end
      end
      # Send response back
      send_data response.encode
    end
  end

  def self.start(options)
    EventMachine::run do
      # UDP Server
      EventMachine::open_datagram_socket options[:host], options[:port], ConnectionUDP, options
    end
  end
end