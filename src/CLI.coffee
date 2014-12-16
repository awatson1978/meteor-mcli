rc = Npm.require('rc')

@practical ?= {}

class practical.CLI

  @instance: null

  registeredCommands: { }

  @get:->
    practical.CLI.instance ?= new CLI()

  constructor: ->
    log.debug("NODE_ENV=#{process.env.NODE_ENV}")

  # ['-o=val1', 'val12', '-o'] -> ['-o=val1 val2', '--opt2']
  # ['--opt1=val1', 'val12', '--opt2'] -> ['--opt1=val11 va12', '--opt2']
  # ['--opt1', ' val1', 'val12', '--opt2'] -> ['--opt1', 'va11 val2', '--opt2']
  # ['--opt1', ' val', '--opt2=val2', 'arg1', 'arg2'] -> No change
  commandLine2argv: (commandLine)->
    argv = commandLine.split(/(?=-+)/);
    argv = argv.concat(argv.pop().split(" "));
    for arg, i in argv
      #Error trim of undefined (check reference change logic problem)
      argv[i] = arg.trim()
      argv[i++] = argv.splice(i,1) + argv[i] if argv[i]=="-"
#    argv = commandLine.split(" ")
#    console.log("Splited:", argv)
#    for arg, i in argv
#      if _.startsWith(arg, '-')
#        return

    argv.unshift("main.js")
    argv.unshift("node")
    process.argv = argv


  executeCommand: ->
    log.debug('CLI.executeCommand()', process.argv)

    commandLine = Meteor?.settings?.commandLine

    if commandLine
      console.log("Unchanged:",commandLine)
      # This is not a meteor bundle, commandLine was provided in Meteor.settings,
      # so we need to add 'node main.js' so rc will function properly.
      @commandLine2argv(commandLine)
      console.log("Result:", process.argv)
      #process.argv.unshift("main.js")
      #process.argv.unshift("node")
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

    log.debug("Executing '#{commandName}' with options:\n", options)

    # Execute the registered command
    command.func options


  # Note: defaultOptions will be mutated by actual command line options.
  registerCommand: (name, func, defaultOptions = {}) ->
    log.debug("CLI.registerCommand()")
    expect(name, "command name is missing").to.be.a("string")
    expect(func, "command function is missing").to.be.a("function")
    expect(defaultOptions, "command defaultOptions is not an object").to.be.a("object")

    log.debug("Registering '#{name}' with default options:\n", defaultOptions)

    @registeredCommands[name] = { func: func, defaultOptions: defaultOptions }


CLI = practical.CLI.get()
