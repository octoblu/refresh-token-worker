_      = require 'lodash'
moment = require 'moment'

class UsersCollection
  constructor: ({@users}) ->

  findExpiredTokens: (callback) =>
    now = Date.now()
    query =
      api:
        $elemMatch:
          expiresOn:
            $lt: now
    @users.find query, (error, users) =>
      return callback error if error?
      result = _.map users, (user) =>
        api = _.find user.api, (api) =>
          return false unless api.expiresOn?
          return true if moment(now).isAfter api.expiresOn
        return if api.validToken? and api.validToken == false
        return {
          type: api.type
          userUuid: user.resource.uuid
        }

      callback null, _.compact result


module.exports = UsersCollection
