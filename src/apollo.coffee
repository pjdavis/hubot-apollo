# Hubot dependencies
# {Robot, Adapter, Response, EnterMessage, LeaveMessage} = require 'hubot'
{Robot, Adapter, EnterMessage, LeaveMessage, TextMessage} = require 'hubot'


Respoke = require('respoke-admin')
request = require('request')

util = require('util')

class Apollo extends Adapter

    constructor: (@robot) ->
        super

    send: (envelope, strings...) ->
      formatImage = (str, callback) ->
        console.log('formatting',str)
        pattern = new RegExp('^(https?:\\/\\/)?'+
          '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|'+
          '((\\d{1,3}\\.){3}\\d{1,3}))'+
          '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*'+
          '(\\?[;&a-z\\d%_.~+=-]*)?'+
          '(\\#[-a-z\\d_]*)?$','i');
        if !pattern.test(str)
          callback null, str
        else
          request {method: 'head', uri: str}, (err, res, body) ->
            if res.headers && res.headers['content-type'] && res.headers['content-type'].match('image.*')
              callback(null, "![#{str}](#{str})")
            else
              callback(null, str)

      {user, room} = envelope
      for str in strings
        formatImage str, (err, formattedStr) =>
          @bot.groups.publish groupId: envelope.room, message: JSON.stringify( text: formattedStr)

      @robot.logger.info "Send", envelope

    reply: (envelope, strings...) ->
        @robot.logger.info "Reply", envelope, strings

    emote: (envelope, strings...) ->
      @send envelope, strings.map((str) -> "/me #{str}")...

    getUsers: (callback) ->
        usersRequest =
            method: 'get',
            uri: "#{@options.uri}/api/accounts",
            headers:
                'Apollo-Account': @options.user,
                'Apollo-Key': @options.key
            json: true

        request usersRequest, (err, res, body) ->
            callback body

    processUsers: (users) ->
        @robot.logger.info 'processing users', users
        for user in users
            if user.id of @robot.brain.data.users
                oldUser = @robot.brain.data.users[user.id]
                for key, value of oldUser
                    unless key of user
                        user[key] = value
                delete @robot.brain.data.users[user.id]
            @robot.brain.userForId user.id, user

    getGroups: (callback) ->
        groupsRequest =
            method: 'get',
            uri: "#{@options.uri}/api/groups",
            headers:
                'Apollo-Account': @options.user,
                'Apollo-Key': @options.key
            json: true

        request groupsRequest, (err, res, body) ->
            callback body

    joinGroups: (groups) ->
        @robot.logger.info 'joining groups', groups
        for group in groups
            @bot.groups.join groupId: group._id
        @robot.brain.set 'groups', groups

    onMessage: (message) ->
        unless JSON.parse(message.body).meta
            @robot.logger.info 'got message!', message
            author = @robot.brain.userForName(message.header.from)
            recievedMessage = new TextMessage(author, JSON.parse(message.body).text, JSON.parse(message.body)._id)
            @receive recievedMessage

    onPubSub: (message) ->
        unless JSON.parse(message.message).meta
            author = @robot.brain.userForName(message.header.from)
            author.reply_to = message.groupId
            author.room = message.header.groupId
            @receive new TextMessage(author, JSON.parse(message.message).text)

    checkCanStart: ->
        if not process.env.HUBOT_APOLLO_USER
            throw new Error("HUBOT_APOLLO_USER is not defined")
        else if not process.env.HUBOT_APOLLO_KEY
            throw new ERROR("HUBOT_APOLLO_KEY is not defined")

    getAuth: (callback) ->
        authRequest =
            method: 'get',
            uri: "#{@options.uri}/auth/tokens",
            headers:
                'Apollo-Account': @options.user,
                'Apollo-Key': @options.key
            json: true

        request authRequest, (err, res, body) ->
            callback(err, res, body)

    setName: (callback) ->
      # set the display name to the name of the bot
      nameRequest =
        method: 'put',
        uri: "#{@options.uri}/api/accounts/#{@options.user}",
        headers:
          'Apollo-Account': @options.user,
          'Apollo-Key': @options.key
        json: true
        body: display: @robot.name
      request nameRequest, (err, res, body) =>
        callback err, res, body

    run: ->
        do @checkCanStart
        @robot.connected = false

        @options =
            user:         process.env.HUBOT_APOLLO_USER
            key:          process.env.HUBOT_APOLLO_KEY
            uri:          process.env.HUBOT_APOLLO_URI or "http://app.apollohd.com/"
            respokeUri:   process.env.HUBOT_APOLLO_RESPOKE_URI or "https://api.respoke.io/v1"

        @bot = new Respoke baseURL: @options.respokeUri
        @.getAuth (err, res, body) =>
            if err
                @robot.logger.error err
            else if res.statusCode != 200
                @robot.logger.error res.statusCode, body
            else
                authToken =
                    tokenId: body.token
                @robot.logger.info "Got auth info for Apollo"
                @bot.auth.sessionToken(
                    authToken
                ).then =>
                    @robot.logger.info 'after session token'
                    @bot.auth.connect endpointId: @options.user
                    @bot.on 'connect', =>
                      unless @robot.connected
                        @setName (err, res, body) =>
                          @robot.name = "[~#{@options.user}]"
                          @emit 'connected'
                          @robot.logger.info 'Bot is Connected!'
                          @.getUsers (users) =>
                              @.processUsers users
                          @.getGroups (groups) =>
                              @.joinGroups groups
                    @bot.on 'message', (message) =>
                        @.onMessage message
                    @bot.on 'pubsub', (message) =>
                        @.onPubSub message
                    @bot.on 'error', (err) =>
                        @robot.logger.debug 'got err', err
                    @bot.on 'connect_error', (err) =>
                        @robot.logger.debug 'got err', err



exports.use = (robot) ->
    new Apollo robot
