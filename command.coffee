_             = require 'lodash'
commander     = require 'commander'
async         = require 'async'
debug         = require('debug')('refresh-token-worker:command')
MeshbluConfig = require 'meshblu-config'
mongojs       = require 'mongojs'
packageJSON   = require './package.json'

UsersCollection    = require './src/users-collection'
ApiOctobluService  = require './src/refresh-token-worker'
RefreshTokenWorker = require './src/refresh-token-worker'

class Command
  parseInt: (str) =>
    parseInt str

  parseOptions: =>
    commander
      .version packageJSON.version
      .option '-s, --single-run', 'perform only one job.'
      .parse process.argv

    {@singleRun} = commander

    if process.env.CREDENTIALS_SINGLE_RUN?
      @singleRun = process.env.CREDENTIALS_SINGLE_RUN == 'true'

    @mongoDBUri = process.env.MONGODB_URI
    @apiOctobluUri = process.env.API_OCTOBLU_URI

  run: =>
    @parseOptions()

    return @die new Error 'Missing environment variable MONGODB_URI' if _.isEmpty @mongoDBUri
    return @die new Error 'Missing environment variable API_OCTOBLU_URI' if _.isEmpty @apiOctobluUri

    meshbluConfig = new MeshbluConfig().toJSON()
    database = mongojs @mongoDBUri, ['users']
    usersCollection = new UsersCollection users: database.users
    apiOctobluService = new ApiOctobluService {@apiOctobluUri,meshbluConfig}

    process.on 'SIGTERM', => @terminate = true

    return @queueWorkerRun {usersCollection}, @die if @singleRun
    async.until @terminated, async.apply(@queueWorkerRun, {usersCollection,apiOctobluService}), @die

  terminated: => @terminate

  queueWorkerRun: ({usersCollection,apiOctobluService,meshbluConfig}, callback) =>
    console.log 'Running...'

    worker = new RefreshTokenWorker {usersCollection,apiOctobluService,meshbluConfig}

    worker.run (error) =>
      if error?
        console.error error.stack
      process.nextTick callback

  die: (error) =>
    return process.exit(0) unless error?
    console.error error.stack
    process.exit 1

commandWork = new Command()
commandWork.run()
