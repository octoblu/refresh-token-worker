_             = require 'lodash'
commander     = require 'commander'
async         = require 'async'
debug         = require('debug')('refresh-token-worker:command')
MeshbluConfig = require 'meshblu-config'
mongojs       = require 'mongojs'
packageJSON   = require './package.json'
UsersCollection    = require './src/users-collection'
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

  run: =>
    @parseOptions()
    
    return @die new Error 'Missing environment variable MONGODB_URI' if _.isEmpty @mongoDBUri

    meshbluConfig = new MeshbluConfig().toJSON()
    database = mongojs @mongoDBUri, ['users']
    usersCollection = new UsersCollection users: database.users

    process.on 'SIGTERM', => @terminate = true

    return @queueWorkerRun {usersCollection, meshbluConfig}, @die if @singleRun
    async.until @terminated, async.apply(@queueWorkerRun, {usersCollection, meshbluConfig}), @die

  terminated: => @terminate

  queueWorkerRun: ({usersCollection, meshbluConfig}, callback) =>
    console.log 'Running...'

    worker = new RefreshTokenWorker {usersCollection,meshbluConfig}

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
