net = require 'net'
debug = require 'debug'
async = require 'async'
pathtoregex = require 'path-to-regexp'
Promise = require 'mpromise'
RoqServiceMessage = require './message'


###
# `RoqService` Class
###
class RoqService extends net.Server

  debug: debug 'roq:service'

  constructor: (options, onConnect)->
    options ?=
      allowHalfOpen: false
      pauseOnConnect: false


    # Define enumerable `endpoints` getter
    endpoints = {}
    Object.defineProperty @, 'endpoints',
      enumerable: true
      get: ()->
        endpoints

    #
    super options
    @.debug 'Creating service'
    @.on 'connection', @.onConnection.bind @


  listen: (port=0)->
    @.debug 'Attempting to accpet incoming connections on port %s', port
    super
    @.on 'listening', @.onServerListening.bind @

  onServerListening: ()->
    @.debug 'Service created %j', arguments


  onConnection: (conn)->
    @.debug "Client connection established [conn%s:%s]", conn.remoteAddress, conn.remotePort

    conn.debug = debug "roq:service:[conn#{conn.remoteAddress}:#{conn.remotePort}]"

    buffer = new String

    conn.on 'data', (data)=>
      #
      transactions = RoqServiceMessage.parse buffer, data.toString('utf-8')

      #
      if transactions

        #
        conn.debug 'Service processing %d transaction(s) %j', transactions.length, transactions
        #
        for t in transactions
          #
          resp = null

          #
          for endpoint, stack of @.endpoints

            if match = stack._match t.endpoint
              conn.debug 'Endpoint matched [%s] %s', stack._path, t.endpoint

              resp = {}

              async.applyEachSeries stack, t, resp, ()=>

                #
                msg = new RoqServiceMessage t.endpoint, resp, t.transaction

                #
                @.writeToConnection conn, "#{msg.encode()}#{RoqServiceMessage.EOT}"

              break

          unless resp
            #
            msg = new RoqServiceMessage t.endpoint, {"[404] Not found.","error": "ResourceException. Service endpoint not found."}, t.transaction

            #
            @.writeToConnection conn, "#{msg.encode()}#{RoqServiceMessage.EOT}"


    #
    conn.on 'end', @.onConnectionEnd.bind @

  #
  writeToConnection: (conn,data)->
    #
    flushed = conn.write data, ()->
      conn.debug 'Data returned to client'

    conn.debug 'Service response was flushed : [%s]', flushed

  #
  onConnectionEnd: (conn)->
    @.debug 'Client disconnected'


  #
  expose: (path,cb)->

    paths = [path] if typeof path is 'string'
    if not path and arguments.length is 1
      paths = Object.keys @.endpoints

    @.debug 'Exposing endpoint with path %j', paths

    for path in paths
      stack = @.endpoints[ path] ?= []

      @.debug 'Endpoint [%s] has stack of length %d', path, stack.length

      stack._path ?= path
      stack._params ?= []
      stack._regex ?= pathtoregex path, stack._params
      stack._match ?= (path)->
        stack._regex.exec path
      stack.push cb if cb


###
# Exports
###
module.exports = (options, cb)->
  new RoqService options, cb

module.exports.RoqService = RoqService
