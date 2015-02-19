net = require 'net'
Promise = require 'mpromise'
debug = require('debug') 'roq:service-client'
RoqServiceMessage = require './message'

###
# Service Client Class
###
class RoqServiceClient extends net.Socket

  constructor: (options, cb)->

    # Default `Socket` options
    options ?=
      allowHalfOpen: false
      readable: true
      writable: true

    # Super
    super options, cb

    # Disable the Nagle algorithm to improve transmission speed
    @.setNoDelay true

    # Define non-enumerable `_buffer` getter
    buffer = new String
    Object.defineProperty @, '_buffer',
      enumerable: false
      get: ()->
        buffer
      set: (val)->
        buffer = val


    # Define non-enumerable `_activeTransactions`
    _activeTransactions = []
    Object.defineProperty @, '_activeTransactions',
      enumerable: false
      get: ()->
        _activeTransactions
      set: (val)->
        _activeTransactions = val


    # Define non-enumerable `_activeTransactionsById` getter
    _activeTransactionsById = {}
    Object.defineProperty @, '_activeTransactionsById',
      enumerable: false
      get: ()->
        _activeTransactionsById
      set: (val)->
        _activeTransactionsById = val


  connect: ()->
    super
    @.on 'data', @.onSocketData.bind @


  onSocketData: (data)->
    # message = RoqServiceMessage.decode data
    debug 'Data received from service %s', data.toString('utf-8')


    transactions = RoqServiceMessage.parse @._buffer, data.toString('utf-8')

    for t in transactions
      debug 'Received response to transaction [%s]', t.transaction

      p = @._activeTransactionsById[ t.transaction]
      p.fulfill t


  request: (endpoint,data,done)->
    debug 'Executing service request %j', data

    msg = new RoqServiceMessage endpoint, data

    write_buffer = "#{msg.encode()}#{RoqServiceMessage.EOT}"

    flushed = @.write write_buffer, ->
      debug 'Service request sent'

    debug 'Service request was flushed : [%s]', flushed


    p = new Promise
    p.onResolve =>
      delete @._activeTransactionsById[ msg.transactionId]
    p.onResolve done

    @._activeTransactionsById[ msg.transactionId] = p

    return p


###
# Exports
###
module.exports = (options, cb)->
  new RoqServiceClient options, cb

module.exports.RoqService = RoqServiceClient
