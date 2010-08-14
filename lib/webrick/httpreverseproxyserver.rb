# encoding: utf-8

require 'webrick'
require 'net/http'

module WEBrick
  # Proxy rule to configure WEBrick::HTTPReverseProxyServer
  class ProxyRule < Struct.new(:pattern, :host, :port, :replacement)
  end

  # == Use case
  #
  # You have several services running as different users for security purposes
  # (they might even be chrooted).  In production we use apache but for testing
  # I prefer to use webrick because I find it more flexible for unit testing.
  #
  #
  # == Configuration
  #
  # The proxy mapping is modelled on the ProxyPass directive of apache. For
  # example:
  #
  #   original URL              proxies  private URL
  #   ------------------------    ==>   --------------------------
  #   /marmalade/index.html             localhost:8081/index.html
  #   /apps/vegemite?id=123             localhost:8082/apps/someservlet?id=123
  #
  # Its not designed to be mod_rewrite (eg. query_string cannot be
  # transformed), but you can specify proxy rules that match a fragment of the
  # original URL and replace it with something else while also sending the new
  # URL to the proxied host and port. So the rules in that example are
  # specified thus:
  #
  #   serverConfig = {
  #     :Port => 80,
  #     :ProxyRules => [
  #       WEBrick::ProxyRule.new('^/marmalade/', 'localhost', 8081, '/'),
  #       WEBrick::ProxyRule.new('vegemite', 'localhost', 8082, 'someservlet')
  #     ]
  #   }
  #   server = WEBrick::HTTPReverseProxyServer.new(serverConfig)
  #
  # ProxyRules is an array so the order is important - the first match is used!
  # If no matches are found then the URL is handled by the local web server
  # normally.
  #
  #
  # == Running a server
  #
  # You may start a server, just like any WEBrick server.
  #
  # To get started using RubyGems, use the following example:
  #
  #   require 'rubygems'
  #   require 'webrick/httpreverseproxyserver'
  #
  #   # create a configuration and a server instance
  #   serverConfig = {
  #     :Port => 8080,
  #     :ProxyRules => [WEBrick::ProxyRule.new('/', 'www.example.com', 80, '/')]
  #   }
  #   server = WEBrick::HTTPReverseProxyServer.new(serverConfig)
  #
  #   # catch ^C to quit cleanly
  #   trap("INT") { server.shutdown }
  #
  #   # start request-response-loop
  #   server.start
  #
  #
  # == Advanced inspection
  #
  # In order to better analyse an HTTP stream, you may easily subclass
  # HTTPReverseProxyServer to add advanced request/response inspection.
  #
  # The following example implements basic Cookie logging:
  #
  #   class CookieLoggingProxy < WEBrick::HTTPReverseProxyServer
  #     def service(request, response)
  #       super.tap do
  #         puts
  #         puts request.request_line
  #         print_cookie_headers request.header
  #         puts response.status_line
  #         print_cookie_headers response.header
  #       end
  #     end
  #
  #     def print_cookie_headers(headers)
  #       headers.each do |key, val|
  #         puts "#{key}: #{val}" if key =~ /cookie/i
  #       end
  #     end
  #   end
  class HTTPReverseProxyServer < HTTPServer
    def service(request, response)
      rule = first_matching_proxy_rule(request)
      if rule.nil?
        super(request, response)
      else
        service_proxy(request, response, rule)
      end
    end

  protected
    # find the *first* matching pattern in the proxy map
    def first_matching_proxy_rule(request)
      matching_rule = @config[:ProxyRules].detect { |rule|
        re = Regexp.new(rule.pattern)
        m = re.match(request.path)
        not m.nil?
      }
      return(matching_rule)
    end

    def service_proxy(request, response, rule)
      host, port, path  = map_to_proxyURI(request, rule)
      # convert WEBrick header (values wrapped in an array) into Net::HTTP
      # header (simple values)
      header = {}
      request.header.keys { |key| header[key] = request.header[key][0] }
      header['x-forwarded-for'] = request.peeraddr[2] # the name of the requesting host
      # send the new request to the private server (hacked from WEBrick::HTTPProxyServer)
      response = nil
      begin
        http = Net::HTTP.new(host, port)
        http.start {
          case request.request_method
          when "GET"  then response = http.get(path, header)
          when "POST" then response = http.post(path, request.body || "", header)
          when "HEAD" then response = http.head(path, header)
          else
            raise HTTPStatus::MethodNotAllowed,
              "unsupported method `#{request.request_method}'."
          end
        }
      rescue => err
        logger.debug("#{err.class}: #{err.message}")
        raise HTTPStatus::ServiceUnavailable, err.message
      end
      response['connection'] = "close"

      # Convert Net::HTTP::HTTPResponse to WEBrick::HTTPResponse
      response.status = response.code.to_i
      response.each { |key, val| response[key] = val }
      response.body = response.body

      # Process contents
      if handler = @config[:ProxyContentHandler]
        handler.call(request, response)
      end
    end

    def map_to_proxyURI(request, rule)
      path = (request.path).sub(%r!#{rule.pattern}!, rule.replacement)
      path += '?' + request.query_string if request.query_string
      return([rule.host, rule.port, path])
    end
  end
end

require 'webrick/httpreverseproxyserver/version'
