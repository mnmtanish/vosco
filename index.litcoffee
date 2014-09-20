VOSCO
=====

Dependencies
------------

    path    = require "path"
    BlameJs = require "blamejs"
    assert  = require "assert"
    {exec}  = require "child_process"

Constructor
-----------

    VOSCO = (@path, @options) ->
      @_validateRepoPath(@path)
      @_validateOptions(@options)
      @env = @_getEnvironmentVariables()
      return @

Setup
-----

    VOSCO::install = (callback) ->
      await @_createRepository defer()
      await @createSnapshot 'Install VOSCO', defer()
      callback null

Repository
----------

    VOSCO::getStatus = (callback) ->
      await @_runGitCommand "status -z", defer(error, stdout, stderr)
      callback null, @_parseStatusOutput(stdout)

    VOSCO::getHistory = (callback) ->
      command = "log --pretty=format:#{@_getLogFormat()} --all"
      await @_runGitCommand command, defer(error, stdout, stderr)
      callback null, @_parseLogOutput(stdout)

    VOSCO::getContentHistory = (paths, callback) ->
      await @_runGitCommand "blame -p #{paths}", defer(error, stdout, stderr)
      callback null, @_parseBlameOutput(stdout)

Snapshot
--------

    VOSCO::createSnapshot = (message, callback) ->
      await @_runGitCommand "add --all .", defer()
      await @_runGitCommand "commit -m \"#{message}\"", defer()
      callback null

    VOSCO::rollbackToSnapshot = (commit, callback) ->
      await @_runGitCommand "clean -f", defer()
      await @_runGitCommand "reset --hard #{commit}", defer()
      callback null

Branch
------

    VOSCO::createBranch = (branch, callback) ->
      await @_runGitCommand "branch #{branch}", defer()
      await @selectBranch branch, defer()
      callback null

    VOSCO::selectBranch = (branch, callback) ->
      await @_runGitCommand "clean -f", defer()
      await @_runGitCommand "checkout #{branch}", defer()
      callback null

    VOSCO::deleteBranch = (branch, callback) ->
      await @_runGitCommand "branch -D #{branch}", defer()
      callback null

Helpers
-------

    VOSCO::_getRepositoryPath = ->
      path.resolve @path, '.vosco'

    VOSCO::_getEnvironmentVariables = ->
      isTest = 0
      if process.env.npm_lifecycle_event is 'test'
        isTest = 1
      GIT_DIR: @_getRepositoryPath()
      GIT_WORK_TREE: @path
      GIT_AUTHOR_NAME: @options.author_name
      GIT_AUTHOR_EMAIL: @options.author_email
      GIT_COMMITTER_NAME: @options.author_name
      GIT_COMMITTER_EMAIL: @options.author_email
      VOSCO_APP_DIR: __dirname
      IS_TEST: isTest

    VOSCO::_getTemplatePath = ->
      path.resolve __dirname, 'template'

    VOSCO::_getLogFormat = ->
      '\'{"commit": "%H", "author": "%an", "email": "%ae", "date": "%ad", "message": "%s"}\''

    VOSCO::_runGitCommand = (command, callback) ->
      options = {cwd: @path, env: @_getEnvironmentVariables()}
      exec "git #{command}", options, callback

    VOSCO::_createRepository = (callback) ->
      await @_runGitCommand "init --template #{@_getTemplatePath()}", defer()
      callback null

Helpers (validate)
-----------------

    VOSCO::_validateRepoPath = (path) ->
      msg = "Invalid repository path"
      assert.equal typeof path, "string", msg

    VOSCO::_validateOptions = (options) ->
      msg = "Invalid options"
      assert.equal typeof options, "object", msg
      assert.equal typeof options.author_name, "string", msg
      assert.equal typeof options.author_email, "string", msg

Helpers (parsers)
-----------------

    VOSCO::_parseStatusOutput = (stdout) ->
      #TODO parse tatus output
      stdout

    VOSCO::_parseLogOutput = (stdout) ->
      lines = stdout.split "\n"
      lines.map (line) -> JSON.parse(line)

    VOSCO::_parseBlameOutput = (stdout) ->
      blamejs = new BlameJs
      blamejs.parseBlame(stdout);
      {lines: blamejs.getLineData(), commits: blamejs.getCommitData()}

Export Module
-------------

    module.exports = VOSCO
