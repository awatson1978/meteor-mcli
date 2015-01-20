rc = Npm.require('rc')
Future = Npm.require('fibers/future');

@practical ?= {}

class practical.CLI

  @instance: null

  registeredCommands: { }

  future: null

  @get:->
    practical.CLI.instance ?= new CLI()

  constructor: ->
    log.debug("NODE_ENV=#{process.env.NODE_ENV}")


  executeCommand: ->
    log.debug('CLI.executeCommand()', process.argv)

    argv = Meteor?.settings?.argv

    if argv
      expect(argv, "Meteor.settings.argv is expected to be an array").to.be.an 'array'
      argv.unshift("main.js")
      argv.unshift("node")
      process.argv = argv
    else
      # In a meteor bundle, the first arg is node, the 2nd main.js, and the 3rd program.json
      # We need to remove program.json, so it will not be interpreted by rc as a command line argument.
      expect(process.argv[2], "program.json was expected at process.argv[2]").to.equal 'program.json'
      process.argv.splice(2, 1)

    # THe first arg after is always the name of the command to execute.

    # Meteor._debug process.argv.join(' ')

    expect(process.argv, "No command specified").to.have.length.above(2)

    commandName = process.argv[2]

    command = @registeredCommands[commandName]
    expect(command, "#{commandName} is not a registered cli command").to.to.be.an 'object'

    # Remove the command, so rc doesn't interpret it as a command line argument.
    process.argv.splice(2, 1)

    options = rc(commandName.replace('-', '_'), command.defaultOptions)

    # Execute the registered command
    if not command.async
      log.debug("Executing '#{commandName}' with options:\n", options)
      command.func options
    else
      log.debug("Executing async '#{commandName}' with options:\n", options)
      @future = new Future()
      command.func options, @done
      @future.wait()


  done: =>
    log.debug("CLI.done()")
    expect(@future, "command is not async, cannot call done").to.be.an 'object'
    expect(@future.isResolved(), "done already called").to.be.false

    @future.return(null)


  # Note: defaultOptions will be mutated by actual command line options.
  registerCommand: (name, func, defaultOptions = {}, async = false) ->
    log.debug("CLI.registerCommand()")
    expect(name, "command name is missing").to.be.a("string")
    expect(func, "command function is missing").to.be.a("function")
    expect(defaultOptions, "command defaultOptions is not an object").to.be.a("object")

    log.debug("Registering '#{name}' with default options:\n", defaultOptions)

    @registeredCommands[name] = { func: func, defaultOptions: defaultOptions, async: async }


CLI = practical.CLI.get()
