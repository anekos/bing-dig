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

if __FILE__ == $0
  if ARGV.empty?
    puts <<EOT
bing-dig [--aspect X] [--color X] [--width X] [--height X] [--size X] [--license X] [--imageType X] [--imageContent X] [--freshness X] <QUERY...>

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

  Dotenv.load

  key = ENV['BING_SEARCH_API_KEY1']
  params = {}
  q = []
  while it = ARGV.shift
    if m = it.match(/^--(.+)/)
      params[m[1]] = ARGV.shift
    else
      q << it
    end
  end

  require 'net/http'

  uri = URI('https://api.cognitive.microsoft.com/bing/v5.0/images/search')
  uri.query = URI.encode_www_form({
    'q' => q.join(' '),
    'count' => 150
  }.merge(params))

  request = Net::HTTP::Post.new(uri.request_uri)
  request['Content-Type'] = 'multipart/form-data'
  request['Ocp-Apim-Subscription-Key'] = key
  request.body = "{body}"

  response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
    http.request(request)
  end

  JSON.parse(response.body)['value'].each do
    |it|
    puts URI.unescape(URI(it['contentUrl']).query.split('&').map {|it| it.split(/=/, 2) } .select {|it| it.first == 'r' } .first.last)
  end
end
