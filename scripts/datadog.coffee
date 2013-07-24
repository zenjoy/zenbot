# Interact with datadog
#

authedRequest = (message, path, action, options, callback) ->
  baseUrl = "https://app.datadoghq.com/api/v1"

  message.http("#{baseUrl}#{path}")
    .query(api_key: process.env.HUBOT_DOG_API_KEY, application_key: process.env.HUBOT_DOG_APP_KEY)
    .header('Content-Length', 0)
    .query(options)[action]() (err, res, body) ->
      callback(err,res,body)

module.exports = (robot) ->
  robot.respond /datadog search (.*)/i, (message) ->
    authedRequest message, '/search', 'get', {q: message.match[1]}, (err, res, body) ->
      json = JSON.parse(body)

      metrics = []
      hosts = []
      response = ""

      if json.results.metrics.length > 0
        metrics = json.results.metrics.map (metric) ->
          "\n - \"#{metric}\""

      if json.results.metrics.length > 0
        hosts = json.results.hosts.map (host) ->
          "\n - \"#{host}\""

      if metrics.length > 0 && hosts.length == 0
        response = "I found following metrics: #{metrics}"
      else if metrics.length == 0 && hosts.length > 0
        response = "I found following hosts: #{hosts}"
      else if metrics.length > 0 && hosts.length > 0
        response = "I found following metrics: #{metrics} \n... and following hosts: #{hosts}"
      else
        response = "I could not find anything..."

      message.send(response)

  robot.respond /graph me -(\d+)(s|h|min|d) (.*)/i, (message) ->
    time = parseInt( message.match[1], 10 )
    unit = message.match[2]
    query = message.match[3]

    switch unit
      when "min" then time = time * 60
      when "h"   then time = time * 60 * 60
      when "d"   then time = time * 60 * 60 * 24

    end = +new Date
    start = end - time

    authedRequest message, '/graph/snapshot', 'get', {metric_query: query, start: start, end: end}, (err, res, body) ->
      json = JSON.parse(body)
      message.send(json.snapshot_url)