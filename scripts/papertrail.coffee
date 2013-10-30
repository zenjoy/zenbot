# Interact with Papertrail
#
# Configuration:
#   HUBOT_PAPERTRAIL_KEY
#
# Commands:
#   hubot log me <something> - Search the logs for <something>

stripColorCodes = require('stripcolorcodes')

authedRequest = (message, path, action, options, callback) ->
  baseUrl = "https://papertrailapp.com/api/v1"

  message.http("#{baseUrl}#{path}")
    .header('X-Papertrail-Token', process.env.HUBOT_PAPERTRAIL_KEY)
    .query(options)[action]() (err, res, body) ->
      callback(err,res,body)

module.exports = (robot) ->
  robot.respond /log me (.*)/i, (message) ->
    authedRequest message, '/events/search.json', 'get', {q: "'#{message.match[1]}'"}, (err, res, body) ->
      # using try - catch
      try
        json = JSON.parse(body)

        if json.events.length > 0
          events = json.events.slice(Math.max(json.events.length - 10, 1))
          log = events.map (event) ->
            "#{event.display_received_at} (#{event.program}): #{stripColorCodes(event.message)}"
          response = "/code " + log.join("\n")
          message.send("Log entries for '#{message.match[1]}' (checkout https://papertrailapp.com/events?q=#{message.match[1]} for more):")
          message.send(response)
        else
          message.send("Nothing found in the logs for '#{message.match[1]}'.")

      catch error
        message.send("Hmm.. something weird happened... #{error}")
