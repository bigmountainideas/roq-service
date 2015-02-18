{RoqService,RoqServiceClient} = require '../index'

describe 'RoqService', ()->

  randomPort = ->
    parseInt (Math.random() * 8000) + 4000

  describe 'service', ()->

    it 'should begin listening for incoming connections', (done)->

      PORT = randomPort()

      s = new RoqService
      s.listen PORT, ()->
        s.address().should.have.property 'port', PORT
        s.close ->
          done()

    it 'should close server connection', (done)->

      PORT = randomPort()

      s = new RoqService
      s.listen PORT, ()->
        s.address().should.be.ok
        s.close ()->
          (s.address() is null).should.be.true
          done()


  describe 'endpoints', ()->

    it 'should expose a service endpoint', (done)->

      PORT = randomPort()

      s = new RoqService

      s.expose '/user/:id', (req, resp, next)->
        resp.hello = "Service responded with: Hello #{req.transaction}"
        next null


      s.expose '/user/:id', (req, resp, next)->
        resp.bye = "Service responded with: Bye #{req.transaction}"
        next null


      s.expose '/accounts/:id', (req, resp, next)->
        next null




      s.endpoints.should.have.property '/user/:id'

      s.listen PORT, ()->

        c = new RoqServiceClient
        c.connect PORT, ()->
          c.request '/user/12345',
            status: 1
          , (err, tran)->

            tran.endpoint.should.eql '/user/12345'

            #
            c.end()
            s.close ()->
              done()
