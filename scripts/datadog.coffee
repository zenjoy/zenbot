# Interact with datadog
#

sleep = require('sleep')

authedRequest = (message, path, action, options, callback) ->
  baseUrl = "https://app.datadoghq.com/api/v1"

  message.http("#{baseUrl}#{path}")
    .query(api_key: "#{process.env.HUBOT_DOG_API_KEY}", application_key: "#{process.env.HUBOT_DOG_APP_KEY}")
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

  robot.respond /graph me -(\d+)(s|h|min|d) (.*)(\(.*\))?/i, (message) ->
    time = parseInt( message.match[1], 10 )
    unit = message.match[2]
    metric = message.match[3]
    scope = message.match[4]
    scope = "*" unless scope?

    switch metric
      when "load"    then query = "system.load.1{#{scope}},system.load.5{#{scope}},system.load.15{#{scope}}"
      when "network" then query = "sum:system.net.bytes_rcvd{#{scope}},sum:system.net.bytes_sent{#{scope}}"
      when "mongodb" then query = "mongodb.opcounters.insertps{#{scope}},mongodb.opcounters.deleteps{#{scope}},mongodb.opcounters.updateps{#{scope}},mongodb.opcounters.queryps{#{scope}},mongodb.opcounters.getmoreps{#{scope}}"
      when "haproxy" then query = "sum:haproxy.backend.bytes.out_rate{#{scope}}"
      else query = "#{metric}{#{scope}}"

    switch unit
      when "min" then time = time * 60
      when "h"   then time = time * 60 * 60
      when "d"   then time = time * 60 * 60 * 24

    end = parseInt((+new Date) / 1000, 10)
    start = (end - time)

    authedRequest message, '/graph/snapshot', 'get', {metric_query: query, start: start, end: end}, (err, res, body) ->
      json = JSON.parse(body)
      snapshot = json.snapshot_url.replace(/https:\/\/s3.amazonaws.com/, "http://datadog.zenjoy.be")
      sleep.sleep(2)
      message.send(snapshot)