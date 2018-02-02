#!/usr/bin/ruby
# vim: set fileencoding=utf-8 :

#   https://dev.cognitive.microsoft.com/docs/services/56b43f0ccf5ff8098cef3808/operations/571fab09dbe2d933e891028f
#   https://www.microsoft.com/cognitive-services/en-us/subscriptions?productId=/products/56ec2de6bca1df083495c610
#   https://azure.microsoft.com/en-us/try/cognitive-services/my-apis/
#   https://msdn.microsoft.com/en-us/library/ff795671.aspx
#   https://docs.microsoft.com/en-us/rest/api/cognitiveservices/bing-images-api-v5-reference#image-imageinsightstoken


require 'dotenv'
require 'json'
require 'uri'
require 'time'
require 'pp'
require 'shellwords'


if __FILE__ == $0
  if ARGV.empty?
    puts <<EOT
bing-dig [--aspect X] [--color X] [--width X] [--height X] [--size X] [--license X] [--imageType X] [--imageContent X] [--freshness X] [--pages X] <QUERY...>

# Option values
aspect
:   Square, Wide, Tall, All
color
:   Black, Blue, Brown, Gray, Green, Orange, Pink, Purple, Red, Teal, White, Yellow
width / height
:   pixels
size
:   Small, Medium, Large, Wallpaper, All
license
:   Any, Public, Share, ShareCommercially, Modify, ModifyCommercially, All
imageType
:   AnimatedGif, Clipart, Line, Photo, Shopping, Transparent
imageContent
:   Face, Portrait
freshness
:   Day, Week, Month
EOT
    exit 1
  end

  PAGE_SIZE = 150

  Dotenv.load

  args = ARGV.dup
  key = ENV['BING_SEARCH_API_KEY1']
  pages = 1
  offset = 0
  params = {}
  q = []
  chrysoberyl_format = false
  while it = args.shift
    if m = it.match(/^--(.+)/)
      name = m[1]

      case name
      when 'pages', 'p'
        pages = args.shift.to_i
      when 'offset', 'o'
        offset = args.shift.to_i
      when 'chrysoberyl'
        chrysoberyl_format = true
      else
        params[name] = args.shift
      end
    else
      q << it
    end
  end

  require 'net/http'

  uri = URI('https://api.cognitive.microsoft.com/bing/v5.0/images/search')
  # uri = URI('https://api.cognitive.microsoft.com/bing/v7.0/images/trending')

  pages.times.each do |page|

    merged = {
      'q' => q.join(' '),
      'count' => PAGE_SIZE,
      'offset' => offset + page * PAGE_SIZE,
    }.merge(params)

    uri.query = URI.encode_www_form(merged)

    begin
      history_file = File.expand_path('~/.bing-dig.history')
      IO.write(history_file, "#{Time.now}\t#{ARGV}\n", mode: 'a')
    rescue
    end

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Content-Type'] = 'multipart/form-data'
    request['Ocp-Apim-Subscription-Key'] = key
    request.body = "{body}"

    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      http.request(request)
    end

    unless Net::HTTPOK === response
      pp JSON.parse(response.body)
      exit 1
    end

    result = JSON.parse(response.body)

    if result['_type'] == 'ErrorResponse'
      pp result
      exit 1
    end

    result['value'].each do
      |it|
      url = URI.unescape(URI.parse(it['contentUrl']).query.split('&').map {|it| it.split('=', 2) } .to_h['r'])

      args = {
        :BING => 1,
        :NAME => it['name'],
        :HOST_PAGE => URI.unescape(URI.parse(it['hostPageUrl']).query.split('&').map {|it| it.split('=', 2) } .to_h['r']),
      }.map do
        |k, v|
        "--meta #{k}=#{v.to_s.shellescape}"
      end.join(' ')

      if chrysoberyl_format
        op = "@push-url #{args} #{url.shellescape}"
        puts(op)
      else
        puts URI.unescape(URI(it['contentUrl']).query.split('&').map {|it| it.split(/=/, 2) } .select {|it| it.first == 'r' } .first.last)
      end
    end
  end
end
