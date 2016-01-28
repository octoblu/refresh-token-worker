_     = require 'lodash'
async = require 'async'
debug = require('debug')('refresh-token-worker:worker')

class RefreshTokenWorker
  constructor: ({@usersCollection,@apiOctobluService}) ->

  run: (callback) =>
    debug 'running...'
    @usersCollection.findExpiredTokens (error, results) =>
      return callback error if error?
      return callback null if _.isEmpty results
      debug 'tokens to refresh', results
      async.eachSeries results, @apiOctobluService.refreshToken, callback

module.exports = RefreshTokenWorker
