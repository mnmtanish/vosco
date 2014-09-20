VOSCO
=====

Dependencies
------------

    path   = require "path"
    assert = require "assert"
    VOSCO  = require ".."

Constructor
-----------

    describe 'VOSCO::constructor', ->
      it "should validate repo path", ->
        vosco = { a: null }
        vosco._validateRepoPath = (a) -> @a = a
        vosco._validateOptions = Function.prototype
        vosco._getEnvironmentVariables = Function.prototype
        VOSCO.call vosco, 'test-path'
        assert.equal vosco.a, 'test-path'

      it "should validate options", ->
        vosco = { a: null }
        vosco._validateRepoPath = Function.prototype
        vosco._validateOptions = (a) -> @a = a
        vosco._getEnvironmentVariables = Function.prototype
        VOSCO.call vosco, 'test-options'
        assert.equal vosco.a, null, 'test-options'

      it "should set environment variables", ->
        vosco = {}
        vosco._validateRepoPath = Function.prototype
        vosco._validateOptions = Function.prototype
        vosco._getEnvironmentVariables = () -> 'test-env-var'
        VOSCO.call vosco
        assert.equal vosco.env, 'test-env-var'

Setup
-----

    describe 'VOSCO::install', ->
      it "should create the repo", (callback) ->
        vosco = {inst_: null, createSnapshot: (msg, cb) -> cb()}
        vosco._createRepository = (cb) -> @inst_ = true; cb()
        await VOSCO::install.call vosco, defer()
        assert.equal vosco.inst_, true
        callback null

      it "should create initial snapshot", (callback) ->
        vosco = {msg_: null, _createRepository: (cb) -> cb()}
        vosco.createSnapshot = (msg, cb) -> @msg_ = msg; cb()
        await VOSCO::install.call vosco, defer()
        assert.equal vosco.msg_, 'Install VOSCO'
        callback null

Repository
----------

    describe 'VOSCO::getStatus', ->
      it "should give current status of repo"

    describe 'VOSCO::getHistory', ->
      it "should give snapshot history", (callback) ->
        vosco = {cmds_: [], _parseLogOutput: Function.prototype}
        vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
        vosco._getLogFormat = () -> '_fmt'
        await VOSCO::getHistory.call vosco, defer(err, out)
        assert.deepEqual vosco.cmds_, ['log --pretty=format:_fmt --all']
        callback null

      it "should parse the output", (callback) ->
        vosco = {blame_: null, _getLogFormat: () -> '_fmt'}
        vosco._runGitCommand = (c, cb) -> cb(null, 'stdout')
        vosco._parseLogOutput = (out, cb) -> @log_ = out; '_parsed'
        await VOSCO::getHistory.call vosco, defer(err, out)
        assert.equal vosco.log_, 'stdout'
        assert.equal out, '_parsed'
        callback null

    describe 'VOSCO::getContentHistory', ->
      it "should give blame info for a given file", (callback) ->
        vosco = {cmds_: [], _parseBlameOutput: Function.prototype}
        vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
        await VOSCO::getContentHistory.call vosco, '_p', defer(err, out)
        assert.deepEqual vosco.cmds_, ['blame -p _p']
        callback null

      it "should parse the output", (callback) ->
        vosco = {blame_: null}
        vosco._runGitCommand = (c, cb) -> cb(null, 'stdout')
        vosco._parseBlameOutput = (out) -> @blame_ = out; '_parsed'
        await VOSCO::getContentHistory.call vosco, '_p', defer(err, out)
        assert.equal vosco.blame_, 'stdout'
        assert.equal out, '_parsed'
        callback null

Snapshot
--------

    describe 'VOSCO::createSnapshot', ->
      it "should create a new snapshot", (callback) ->
        vosco = {cmds_: []}
        vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
        await VOSCO::createSnapshot.call vosco, '_msg', defer()
        assert.deepEqual vosco.cmds_, ['add --all .', 'commit -m "_msg"']
        callback null

    describe 'VOSCO::rollbackToSnapshot', ->
      it "should rollback to an older snapshot", (callback) ->
        vosco = {cmds_: []}
        vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
        await VOSCO::rollbackToSnapshot.call vosco, '_h', defer()
        assert.deepEqual vosco.cmds_, ['clean -f', 'reset --hard _h']
        callback null

Branch
------

    describe 'VOSCO::createBranch', ->
      it "should create a new branch", (callback) ->
        vosco = {cmds_: [], selectBranch: (b, cb) -> cb()}
        vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
        await VOSCO::createBranch.call vosco, '_b', defer()
        assert.deepEqual vosco.cmds_, ['branch _b']
        callback null

      it "should switch to new branch", (callback) ->
        vosco = {select_: null, _runGitCommand: (c, cb) -> cb()}
        vosco.selectBranch = (branch, cb) -> @select_ = branch; cb()
        await VOSCO::createBranch.call vosco, '_b', defer()
        assert.equal vosco.select_, '_b'
        callback null

    describe 'VOSCO::selectBranch', ->
      it "should witch to a branch", (callback) ->
        vosco = {cmds_: []}
        vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
        await VOSCO::selectBranch.call vosco, '_b', defer()
        assert.deepEqual vosco.cmds_, ['clean -f', 'checkout _b']
        callback null

    describe 'VOSCO::deleteBranch', ->
      it "should delete a branch", (callback) ->
        vosco = {cmds_: []}
        vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
        await VOSCO::deleteBranch.call vosco, '_b', defer()
        assert.deepEqual vosco.cmds_, ['branch -D _b']
        callback null

Helpers
-------

    describe 'VOSCO::_getRepositoryPath', ->
      it "should return vosco repo path", ->
        vosco = {path: '/'}
        output = VOSCO::_getRepositoryPath.call vosco
        assert.equal output, '/.vosco'

    describe 'VOSCO::_getEnvironmentVariables', ->
      it "should return environment variables (dev)", ->
        vosco =
          path: '_path',
          _getRepositoryPath: () -> '_dir'
          options: {author_name: '_name', author_email: '_email'}
        env = VOSCO::_getEnvironmentVariables.call vosco
        assert.deepEqual env,
          GIT_DIR: '_dir'
          GIT_WORK_TREE: '_path'
          GIT_AUTHOR_NAME: '_name'
          GIT_AUTHOR_EMAIL: '_email'
          GIT_COMMITTER_NAME: '_name'
          GIT_COMMITTER_EMAIL: '_email'
          VOSCO_APP_DIR: path.resolve(__dirname, '..')
          IS_TEST: 1

      it "should return environment variables (prod)", ->
        process.env.npm_lifecycle_event = 'prod'
        vosco =
          path: '_path',
          _getRepositoryPath: () -> '_dir'
          options: {author_name: '_name', author_email: '_email'}
        env = VOSCO::_getEnvironmentVariables.call vosco
        assert.deepEqual env,
          GIT_DIR: '_dir'
          GIT_WORK_TREE: '_path'
          GIT_AUTHOR_NAME: '_name'
          GIT_AUTHOR_EMAIL: '_email'
          GIT_COMMITTER_NAME: '_name'
          GIT_COMMITTER_EMAIL: '_email'
          VOSCO_APP_DIR: path.resolve(__dirname, '..')
          IS_TEST: 0
        process.env.npm_lifecycle_event = 'test'

    describe 'VOSCO::_getTemplatePath', ->
      it "should return template path", ->
        expected = path.resolve __dirname, '..', 'template'
        assert.equal VOSCO::_getTemplatePath(), expected

    describe 'VOSCO::_getLogFormat', ->
      it "should return JSON log format", ->
        assert.equal VOSCO::_getLogFormat(), '\'{"commit": "%H", "author": "%an", "email": "%ae", "date": "%ad", "message": "%s"}\''

    describe 'VOSCO::_runGitCommand', ->
      it "should run a command with git", (callback) ->
        repo_path = path.resolve __dirname, '..'
        vosco = {path: __dirname, _getEnvironmentVariables: Function.prototype}
        await VOSCO::_runGitCommand.call vosco, '--version', defer(err, out)
        assert.equal err, null
        assert.equal out.substr(0, 3), 'git'
        callback null

    describe 'VOSCO::_createRepository', ->
      it "should create repo with template", (callback) ->
        vosco = {cmds_: [], _getTemplatePath: () -> '_dir'}
        vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
        await VOSCO::_createRepository.call vosco, defer()
        assert.deepEqual vosco.cmds_, ['init --template _dir']
        callback null

Helpers (validate)
-----------------

    describe 'VOSCO::_validateRepoPath', ->
      it "should validate repository path", ->
        assert.throws () -> VOSCO::_validateRepoPath.call {}, null
        assert.doesNotThrow () -> VOSCO::_validateRepoPath.call {}, '/'

    describe 'VOSCO::_validateOptions', ->
      it "should validate options", ->
        test_opts = { author_name: 'n', author_email: 'e' }
        assert.throws () -> VOSCO::_validateOptions.call {}, null
        assert.doesNotThrow () -> VOSCO::_validateOptions.call {}, test_opts

Helpers (parsers)
-----------------

    describe 'VOSCO::_parseStatusOutput', ->
      it "should parse and return status output"

    describe 'VOSCO::_parseLogOutput', ->
      it "should parse and return log output", ->
        input = '{"foo": "bar"}\n{"bar": "baz"}'
        output = VOSCO::_parseLogOutput.call {}, input
        assert.deepEqual output, [{foo: 'bar'}, {bar: 'baz'}]

    describe 'VOSCO::_parseBlameOutput', ->
      it "should parse and return blame output", ->
        input = 'test input'
        output = VOSCO::_parseBlameOutput.call {}, input
        assert.equal typeof output.lines, 'object'
        assert.equal typeof output.commits, 'object'
