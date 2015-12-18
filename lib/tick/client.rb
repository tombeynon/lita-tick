module Tick
  module Client
    class Unauthorized < RuntimeError
      def message
        "Incorrect API token"
      end
    end

    def api_url
      Tick.api_url
    end

    def api_token
      Tick.api_token
    end

    def api_contact
      Tick.api_contact
    end

    def get(path, params={})
      url = URI.join(api_url, path)
      url.query = URI.encode_www_form(params)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      req = Net::HTTP::Get.new(url, {'User-Agent' => "Lita-Tick (#{api_contact})"})
      req['authorization'] = "Token token=#{api_token}"

      response = http.request(req)
      handle_response(response)
    end

    def post(path, params={})
      url = URI.join(api_url, path)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      req = Net::HTTP::Post.new(url, {'User-Agent' => "Lita-Tick (#{api_contact}"})
      req['authorization'] = "Token token=#{api_token}"
      req.set_form_data(params)

      response = http.request(req)
      handle_response(response)
    end

    def handle_response(response)
      case response
      when Net::HTTPSuccess then
        JSON.parse response.body
      when Net::HTTPUnauthorized then
        raise Unauthorized
      end
    end
  end
end
