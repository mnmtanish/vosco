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

    VOSCO::rollbackToSnapshot = (hash, callback) ->
      await @_runGitCommand "checkout -- .", defer()
      await @_runGitCommand "clean -f", defer()
      await @_runGitCommand "reset --hard #{hash}", defer()
      callback null

Branch
------

    VOSCO::getBranches = (callback) ->
      await @_runGitCommand "branch", defer(error, stdout, stderr)
      await @_parseBranchOutput stdout, defer(error, branches, currentBranch)
      callback null, branches, currentBranch

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
      GIT_DIR: @_getRepositoryPath()
      GIT_WORK_TREE: @path
      GIT_AUTHOR_NAME: @options.author_name
      GIT_AUTHOR_EMAIL: @options.author_email
      GIT_COMMITTER_NAME: @options.author_name
      GIT_COMMITTER_EMAIL: @options.author_email
      VOSCO_APP_DIR: __dirname
      VOSCO_SOFTWARE_LIST: path.resolve @path, 'vosco-software-list'

    VOSCO::_getTemplatePath = ->
      path.resolve __dirname, 'template'

    VOSCO::_getLogFormat = ->
      '\'{"hash": "%H", "author": "%an", "email": "%ae", "date": "%ad", "message": "%s"}\''

    VOSCO::_runGitCommand = (command, callback) ->
      options = {cwd: @path, env: @_getEnvironmentVariables()}
      await exec "git #{command}", options, defer(error, stdout, stderr)
      callback error, stdout, stderr

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
      # TODO handle empty stdout
      types = {' M': 'modified', ' D': 'removed', '??': 'untracked'}
      parser = (line) -> {type: types[line.substr(0, 2)], path: line.substr(3)}
      lines = stdout.split('\u0000').map parser
      lines.filter (line) -> !!line.type

    VOSCO::_parseLogOutput = (stdout) ->
      lines = stdout.split "\n"
      lines.map (line) -> JSON.parse(line)

    VOSCO::_parseBlameOutput = (stdout) ->
      blamejs = new BlameJs
      blamejs.parseBlame(stdout);
      {lines: blamejs.getLineData(), commits: blamejs.getCommitData()}

    VOSCO::_parseBranchOutput = (stdout, callback) ->
      lines = stdout.split("\n").filter (line) -> line != ''
      current = lines.filter((line) -> line[0] == '*')[0].substr(2)
      branches = lines.map (line) -> line.substr(2)
      callback null, branches, current

Export Module
-------------

    module.exports = VOSCO
