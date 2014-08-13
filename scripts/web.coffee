module.exports = (robot) ->
  robot.router.get "/", (req, res) ->
    robot.logger.info "Received GET /"
    res.writeHead 200, {'Content-Type': 'text/plain'}
    res.end 'Thanks'
