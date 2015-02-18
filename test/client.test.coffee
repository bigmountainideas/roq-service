{RoqServiceClient,RoqService} = require '../index'

describe 'RoqServiceClient', ()->


  randomPort = ->
    parseInt (Math.random() * 8000) + 4000


  describe 'connection', ->

    it 'should succeed', (done)->

      PORT = randomPort()

      s = new RoqService
      s.listen PORT, ()->
        s.address().should.have.property 'port', PORT


        c = new RoqServiceClient
        c.connect PORT, ()->
          c.destroy()
          c.end()
          s.close ->
            done()

    it 'should fail with invalid port', (done)->

      PORT = randomPort()

      s = new RoqService
      s.listen PORT, ()->
        s.address().should.have.property 'port', PORT

        c = new RoqServiceClient
        c.connect 2000, ()->
        c.on 'error', (err)->

          err.should.have.property 'code', 'ECONNREFUSED'

          c.end()
          s.close ->
            done()


  describe 'sending message', ->

    PORT = randomPort()

    s = new RoqService
    c = null
    s.listen PORT, ()->

      c = new RoqServiceClient


    it 'should receive message response from service', (done)->

      c.connect PORT, ()->

        c.request '/user/12345',
          time: Date.now()
        , (err, tran)->
          tran.should.be.ok
          done()
