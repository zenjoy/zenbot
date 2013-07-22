# Description:
#   Play music. At your office. Like a boss. https://github.com/play/play
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_PLAY_URL
#   HUBOT_PLAY_TOKEN
#
# Commands:
#   hubot play - Plays music.
#   hubot play next - Plays the next song.
#   hubot skip - Plays the next song.
#   hubot play again - Plays the previous song.
#   hubot what's playing - Returns the currently-played song.
#   hubot what's next - Returns next song in the queue.
#   hubot I want this song - Returns a download link for the current song.
#   hubot I want this album - Returns a download link for the current album.
#   hubot play <artist> - Queue up ten songs from a given artist.
#   hubot play <album> - Queue up an entire album.
#   hubot play <song> - Queue up a particular song. This grabs the first song by playcount.
#   hubot play <something> right [fucking] now - Play this shit right now.
#   hubot where's play - Gives you the URL to the web app.
#   hubot volume? - Returns the current volume level.
#   hubot volume [0-100] - Sets the volume.
#   hubot pause - Mute play.
#   hubot unpause - Unmute play.
#   hubot say <message> - `say` your message over your speakers.
#   hubot clear play - Clears the Play queue.
#
# Author:
#   holman

URL = "#{process.env.HUBOT_PLAY_URL}/api"

authedRequest = (message, path, action, options, callback) ->
  message.http("#{URL}#{path}")
    .query(login: message.message.user.githubLogin, token: "#{process.env.HUBOT_PLAY_TOKEN}")
    .header('Content-Length', 0)
    .query(options)[action]() (err, res, body) ->
      callback(err,res,body)

module.exports = (robot) ->
  robot.respond /where'?s play\??/i, (message) ->
    message.finish()
    authedRequest message, '/stream_url', 'get', {}, (err, res, body) ->
      message.send("play's at #{URL} and you can stream from #{body}")

  robot.respond /what'?s playing\??/i, (message) ->
    authedRequest message, '/now_playing', 'get', {}, (err, res, body) ->
      json = JSON.parse(body)
      str = "\"#{json.title}\" by #{json.artist_name}, from \"#{json.album_name}\"."
      message.send("#{process.env.HUBOT_PLAY_URL}#{json.album_art_path}")
      message.send("Now playing " + str)

  robot.respond /what'?s next\??/i, (message) ->
    authedRequest message, '/queue', 'get', {}, (err, res, body) ->
      json = JSON.parse(body)
      song = json.songs[1]
      if typeof(song) == "object"
        message.send("We will play this awesome track \"#{song.name}\" by #{song.artist} in just a minute!")
      else
        message.send("The queue is empty :( Try adding some songs, eh?")

  robot.respond /what'?s in queue\??/i, (message) ->
    authedRequest message, '/queue', 'get', {}, (err, res, body) ->
      json = JSON.parse(body)
      songs = json.songs
      if typeof(songs) == "object"
        str = json.songs.map (song) ->
          "\n - \"#{song.title}\" by #{song.artist_name}"
        str.join('')
        message.send("Our next songs are: #{str}")
      else
        message.send("The queue is empty :( Try adding some songs, eh?")

  robot.respond /skip|(play next)|next/i, (message) ->
    message.finish()
    authedRequest message, '/next', 'post', {}, (err, res, body) ->
      json = JSON.parse(body)
      message.send("On to the next one: \"#{json.title}\" by #{json.artist_name}, from \"#{json.album_name}\".")

  #
  # VOLUME
  #

  robot.respond /app volume\?/i, (message) ->
    message.finish()
    authedRequest message, '/volume', 'get', {}, (err, res, body) ->
      message.send("Yo @#{message.message.user.mention_name}, the volume is #{body} :mega:")

  robot.respond /volume (.*)/i, (message) ->
    params = {volume: message.match[1]}
    authedRequest message, '/volume', 'put', params, (err, res, body) ->
      message.send("Bumped the volume to #{body}, @#{message.message.user.mention_name}")

  robot.respond /volume\?/i, (message) ->
    message.finish()
    authedRequest message, '/volume', 'get', {}, (err, res, body) ->
      message.send("Yo @#{message.message.user.mention_name}, the volume is #{body} LOUD!")

  robot.respond /volume ([+-])?(.*)/i, (message) ->
    if message.match[1]
      multiplier = if message.match[1][0] == '+' then 1 else -1

      authedRequest message, '/volume', 'get', {}, (err, res, body) ->
        newVolume = parseInt(body) + parseInt(message.match[2]) * multiplier

        params = {volume: newVolume}
        authedRequest message, '/volume', 'put', params, (err, res, body) ->
          message.send("Bumped the volume to #{body}, @#{message.message.user.mention_name}")
    else
      params = {volume: message.match[2]}
      authedRequest message, '/system-volume', 'put', params, (err, res, body) ->
        message.send("Bumped the volume to #{body}, @#{message.message.user.mention_name}")

  robot.respond /quiet!|pause|(pause play)|(play pause)/i, (message) ->
    message.finish()
    params = {volume: 0}
    authedRequest message, '/volume', 'put', params, (err, res, body) ->
      message.send("The office is now quiet. (But the stream lives on!)")

  robot.respond /play!|unpause|(unpause play)|(play unpause)/i, (message) ->
    message.finish()
    params = {volume: 50}
    authedRequest message, '/volume', 'put', params, (err, res, body) ->
      message.send("The office is now rockin' at half-volume.")

  robot.respond /start play/i, (message) ->
    message.finish()
    authedRequest message, '/play', 'post', {}, (err, res, body) ->
      json = JSON.parse(body)
      message.send("Okay! :-)")

  robot.respond /stop play/i, (message) ->
    message.finish()
    authedRequest message, '/pause', 'post', {}, (err, res, body) ->
      json = JSON.parse(body)
      message.send("Okay. :-(")

  #
  # PLAYING
  #

  robot.respond /queue (.*)/i, (message) ->
    params = {search: message.match[1]}
    authedRequest message, '/search/add', 'post', params, (err, res, body) ->
      json = JSON.parse(body)

      unless json instanceof Array
        return message.send("That doesn't exist in Play. Or anywhere, probably. I'm a total hipster.")

      str = json.map (song) ->
        "\n - \"#{song.title}\" by #{song.artist_name}"
      str.join('')

      message.send("Added this to the queue: #{str}")

  robot.respond /play (.*)/i, (message) ->
    params = {search: message.match[1], clear: 1}
    authedRequest message, '/search/add', 'post', params, (err, res, body) ->
      json = JSON.parse(body)

      unless json instanceof Array
        return message.send("That doesn't exist in Play. Or anywhere, probably. I'm a total hipster.")

      str = json.map (song) ->
        "\n - \"#{song.title}\" by #{song.artist_name}"
      str.join('')

      message.send("Playing now: #{str}")

  robot.respond /search (.*)/i, (message) ->
    params = {search: message.match[1]}
    authedRequest message, '/search', 'post', params, (err, res, body) ->
      json = JSON.parse(body)

      unless json instanceof Array
        return message.send("Our DJ does not have that. It's not in our library. Or anywhere, probably.")

      str = json.map (song) ->
        "\n - \"#{song.title}\" by #{song.artist_name}"
      str.join('')

      message.send("Our DJ has following songs: #{str}")

  robot.respond /(reset queue)|(implode)/i, (message) ->
    authedRequest message, '/queue', 'delete', {}, (err, res, body) ->
      message.send("You killed it all!!")
