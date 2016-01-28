shmock      = require '@octoblu/shmock'
mongojs     = require 'mongojs'
RefreshTokenWorker = require '../../src/refresh-token-worker'
UsersCollection    = require '../../src/users-collection'
ApiOctobluService  = require '../../src/api-octoblu-service'

describe 'Refresh Tokens', ->
  beforeEach ->
    @mongoDBUri = 'refresh-token-test-database'
    @database = mongojs @mongoDBUri, ['users']

  beforeEach (done) ->
    @database.users.remove => done()

  beforeEach ->
    @apiOctoblu = shmock 0xd00d

    meshbluConfig =
      uuid: 'refresh-worker-uuid'
      token: 'refresh-worker-token'
      server: 'localhost'
      port: 0xd00d

    usersCollection = new UsersCollection users: @database.users
    apiOctobluService = new ApiOctobluService {apiOctobluUri: "http://localhost:#{0xd00d}", meshbluConfig}

    @sut = new RefreshTokenWorker {usersCollection,apiOctobluService}

  afterEach (done) ->
    @apiOctoblu.close done

  describe 'when a user with an expired token is in the database', ->
    beforeEach (done) ->
      user =
        resource:
          uuid: 'user-uuid'
        api: [
          expiresOn: Date.now() - 1000
          type:      'channel:github'
        ]
      @database.users.insert user, done

    describe 'when the worker runs once', ->
      beforeEach (done) ->
        refreshWorkerAuth = new Buffer('refresh-worker-uuid:refresh-worker-token').toString('base64')

        @refreshTheToken = @apiOctoblu
          .post '/api/workers/refresh-token'
          .set 'Authorization', "Basic #{refreshWorkerAuth}"
          .send
            userUuid: 'user-uuid'
            type:     'channel:github'
          .reply 204

        @sut.run (error) => done error

      it 'should hit up api.octoblu.com', ->
        @refreshTheToken.done()

  describe 'when a user with an valid token is in the database', ->
    beforeEach (done) ->
      user =
        resource:
          uuid: 'user-uuid'
        api: [
          expiresOn: Date.now() + 1000
          type:      'channel:github'
        ]
      @database.users.insert user, done

    describe 'when the worker runs once', ->
      beforeEach (done) ->
        refreshWorkerAuth = new Buffer('refresh-worker-uuid:refresh-worker-token').toString('base64')

        @refreshTheToken = @apiOctoblu
          .post '/api/worker/refresh-token'
          .set 'Authorization', "Basic #{refreshWorkerAuth}"
          .send
            userUuid: 'user-uuid'
            type:     'channel:github'
          .reply 204

        @sut.run (error) => done error

      it 'should not hit up api.octoblu.com', ->
        expect(@refreshTheToken.isDone).to.be.false

  describe 'when no users are available', ->
    describe 'when the worker runs once', ->
      beforeEach (done) ->
        refreshWorkerAuth = new Buffer('refresh-worker-uuid:refresh-worker-token').toString('base64')

        @refreshTheToken = @apiOctoblu
          .post '/api/worker/refresh-token'
          .set 'Authorization', "Basic #{refreshWorkerAuth}"
          .send
            userUuid: 'user-uuid'
            type:     'channel:github'
          .reply 204

        @sut.run (error) => done error

      it 'should not hit up api.octoblu.com', ->
        expect(@refreshTheToken.isDone).to.be.false
