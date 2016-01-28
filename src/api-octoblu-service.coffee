request = require 'request'

class ApiOctobluService
  constructor: ({@apiOctobluUri,@meshbluConfig}) ->

  refreshToken: ({type, userUuid}, callback) =>
    options =
      baseUrl: @apiOctobluUri
      uri: '/api/workers/refresh-token'
      auth:
        username: @meshbluConfig.uuid
        password: @meshbluConfig.token
      json:
        type: type
        userUuid: userUuid

    request.post options, (error, response, body) =>
      return callback error if error?
      return callback new Error "Invalid Response #{response.statusCode} Body: #{body}" if response.statusCode > 299
      callback null

module.exports = ApiOctobluService
