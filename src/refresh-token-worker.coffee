_     = require 'lodash'
async = require 'async'
debug = require('debug')('refresh-token-worker:worker')

class RefreshTokenWorker
  constructor: ({@usersCollection,@apiOctobluService,@tokenDelay}) ->

  run: (callback) =>
    debug 'running...'
    @usersCollection.findExpiredTokens (error, results) =>
      return callback error if error?
      return callback null if _.isEmpty results
      debug 'tokens to refresh', results
      eachItem = (item, callback) =>
        @apiOctobluService.refreshToken item, (error) =>
          console.error error.stack if error?
          _.delay callback, @tokenDelay

      async.eachSeries results, eachItem, callback

module.exports = RefreshTokenWorker
