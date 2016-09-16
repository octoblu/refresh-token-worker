_      = require 'lodash'
moment = require 'moment'
debug = require('debug')('refresh-token-worker:users-collection')

class UsersCollection
  constructor: ({@users, @delay}) ->

  findExpiredTokens: (callback) =>
    nextRun = Date.now() + (@delay * 1000 * 60) + (2000 * 60)
    prevRun = Date.now() - ((@delay * 1000 * 60) * 2)
    query =
      api:
        $elemMatch:
          expiresOn:
            $lt: nextRun
            $gt: prevRun
    debug {query}
    @users.find query, (error, users) =>
      return callback error if error?
      result = _.map users, (user) =>
        apis = _.filter user.api, (api) =>
          return false unless api.expiresOn?
          debug {api}
          return false if moment(api.expiresOn).isBefore prevRun
          return true if moment(nextRun).isAfter api.expiresOn
        return _.map apis, (api) =>
          return if api.validToken? and api.validToken == false
          return {
            type: api.type
            userUuid: user.resource.uuid
          }

      callback null, _.compact _.flatten result


module.exports = UsersCollection
