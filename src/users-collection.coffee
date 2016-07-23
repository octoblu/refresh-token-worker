_      = require 'lodash'
moment = require 'moment'

class UsersCollection
  constructor: ({@users, @delay}) ->

  findExpiredTokens: (callback) =>
    nextRun = Date.now() + (@delay * 1000 * 60) + (2000 * 60)
    query =
      api:
        $elemMatch:
          expiresOn:
            $lt: nextRun
    @users.find query, (error, users) =>
      return callback error if error?
      result = _.map users, (user) =>
        api = _.find user.api, (api) =>
          return false unless api.expiresOn?
          return true if moment(nextRun).isAfter api.expiresOn
        return if api.validToken? and api.validToken == false
        return {
          type: api.type
          userUuid: user.resource.uuid
        }

      callback null, _.compact result


module.exports = UsersCollection
