Dependencies
------------

    path   = require "path"
    assert = require "assert"
    {exec} = require "child_process"
    VOSCO  = require ".."

VOSCO
=====

    describe 'VOSCO', ->

Constructor
-----------

      describe 'constructor', ->
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

      describe 'install', ->
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

This test will always pass no matter the repository directory gets removed or not. TO properly test this, create a test directory before running the test.

      describe 'uninstall', ->
        it "should remove the repo", (callback) ->
          vosco = {_getRepositoryPath: () -> '/tmp/aaa'}
          await exec 'mkdir /tmp/aaa', defer()
          await exec 'mkdir /tmp/aaa/.vosco', defer()
          await VOSCO::uninstall.call vosco, defer()
          await VOSCO::isInstalled.call vosco, defer(error, status)
          assert.equal status, false
          callback null

      describe 'isInstalled', ->
        it "test whether repo is installed", (callback) ->
          vosco = {_getRepositoryPath: () -> '/tmp/aaa'}
          await VOSCO::isInstalled.call vosco, defer(error, status)
          assert.equal status, false
          await exec 'mkdir /tmp/aaa', defer()
          await exec 'mkdir /tmp/aaa/hooks', defer()
          await VOSCO::isInstalled.call vosco, defer(error, status)
          assert.equal status, true
          callback null

  Repository
  ----------

      describe 'getStatus', ->
        it "should give current status of repo", (callback) ->
          vosco = {cmds_: [], _parseStatusOutput: Function.prototype}
          vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
          await VOSCO::getStatus.call vosco, defer()
          assert.deepEqual vosco.cmds_, ['status -z']
          callback null

      describe 'getHistory', ->
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

      describe 'getContentHistory', ->
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

      describe 'previewSnapshot', ->
        it "should give snapshot changes", (callback) ->
          vosco = {cmds_: []}
          vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb(null, 'stdout')
          await VOSCO::previewSnapshot.call vosco, '_h', defer(err, out)
          assert.equal out, 'stdout'
          assert.deepEqual vosco.cmds_, ['show --format=oneline _h']
          callback null

      describe 'createSnapshot', ->
        it "should create a new snapshot", (callback) ->
          vosco = {cmds_: []}
          vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
          await VOSCO::createSnapshot.call vosco, '_msg', defer()
          assert.deepEqual vosco.cmds_, ['add --all etc', 'commit -m "_msg"']
          callback null

      describe 'rollbackToSnapshot', ->
        it "should rollback to an older snapshot", (callback) ->
          vosco = {cmds_: []}
          vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
          await VOSCO::rollbackToSnapshot.call vosco, '_h', defer()
          assert.deepEqual vosco.cmds_, [
            'checkout -- .',
            'clean -f',
            'reset --hard _h']
          callback null

  Branch
  ------

      describe 'getBranches', ->
        it "should give branches list/curent branch", (callback) ->
          vosco = {cmds_: [], _parseBranchOutput: (b, cb) -> cb()}
          vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
          await VOSCO::getBranches.call vosco, defer()
          assert.deepEqual vosco.cmds_, ['branch']
          callback null

        it "should parse the output", (callback) ->
          vosco = {cmds_: [], br_: null}
          vosco._runGitCommand = (c, cb) -> cb(null, 'stdout')
          vosco._parseBranchOutput = (out, cb) -> @br_ = out; cb null, 'l', 'c'
          await VOSCO::getBranches.call vosco, defer(err, list, current)
          assert.equal vosco.br_, 'stdout'
          assert.equal list, 'l'
          assert.equal current, 'c'
          callback null

      describe 'createBranch', ->
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

      describe 'selectBranch', ->
        it "should switch to a branch", (callback) ->
          vosco = {cmds_: []}
          vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
          await VOSCO::selectBranch.call vosco, '_b', defer()
          assert.deepEqual vosco.cmds_, ['clean -f', 'checkout _b']
          callback null

      describe 'deleteBranch', ->
        it "should delete a branch", (callback) ->
          vosco = {cmds_: []}
          vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
          await VOSCO::deleteBranch.call vosco, '_b', defer()
          assert.deepEqual vosco.cmds_, ['branch -D _b']
          callback null

  Helpers
  -------

      describe '_getRepositoryPath', ->
        it "should return vosco repo path", ->
          vosco = {path: '/'}
          output = VOSCO::_getRepositoryPath.call vosco
          assert.equal output, '/.vosco'

      describe '_getEnvironmentVariables', ->
        it "should return environment variables", ->
          vosco =
            path: '_path',
            _getRepositoryPath: () -> '_dir'
            options: {author_name: '_name', author_email: '_email'}
          env = VOSCO::_getEnvironmentVariables.call vosco
          listPath = path.resolve('_path', 'etc', 'vosco-software-list')
          assert.deepEqual env,
            GIT_DIR: '_dir'
            GIT_WORK_TREE: '_path'
            GIT_AUTHOR_NAME: '_name'
            GIT_AUTHOR_EMAIL: '_email'
            GIT_COMMITTER_NAME: '_name'
            GIT_COMMITTER_EMAIL: '_email'
            VOSCO_APP_DIR: path.resolve(__dirname, '..')
            VOSCO_SOFTWARE_LIST: listPath

      describe '_getTemplatePath', ->
        it "should return template path", ->
          expected = path.resolve __dirname, '..', 'template'
          assert.equal VOSCO::_getTemplatePath(), expected

      describe '_getLogFormat', ->
        it "should return JSON log format", ->
          assert.equal VOSCO::_getLogFormat(), '\'{"hash": "%H", "author": "%an", "email": "%ae", "date": "%ad", "message": "%s"}\''

      describe '_runGitCommand', ->
        it "should run a command with git", (callback) ->
          repo_path = path.resolve __dirname, '..'
          vosco = {path: __dirname}
          vosco._getEnvironmentVariables = Function.prototype
          await VOSCO::_runGitCommand.call vosco, '--version', defer(err, out)
          assert.equal err, null
          assert.equal out.substr(0, 3), 'git'
          callback null

      describe '_createRepository', ->
        it "should create repo with template", (callback) ->
          vosco = {cmds_: [], _getTemplatePath: () -> '_dir'}
          vosco._runGitCommand = (c, cb) -> @cmds_.push(c); cb()
          await VOSCO::_createRepository.call vosco, defer()
          assert.deepEqual vosco.cmds_, ['init --template _dir']
          callback null

  Helpers (validate)
  -----------------

      describe '_validateRepoPath', ->
        it "should validate repository path", ->
          assert.throws () -> VOSCO::_validateRepoPath.call {}, null
          assert.doesNotThrow () -> VOSCO::_validateRepoPath.call {}, '/'

      describe '_validateOptions', ->
        it "should validate options", ->
          test_opts = { author_name: 'n', author_email: 'e' }
          assert.throws () -> VOSCO::_validateOptions.call {}, null
          assert.doesNotThrow () -> VOSCO::_validateOptions.call {}, test_opts

  Helpers (parsers)
  -----------------

      describe '_parseStatusOutput', ->
        it "should parse and return status output", ->
          input = ' M _modified\u0000 D _removed\u0000?? _untracked'
          output = VOSCO::_parseStatusOutput.call {}, input
          assert.deepEqual output, [
            { type: 'modified', path: '_modified' }
            { type: 'removed', path: '_removed' }
            { type: 'untracked', path: '_untracked' }]

      describe '_parseLogOutput', ->
        it "should parse and return log output", ->
          input = '{"foo": "bar"}\n{"bar": "baz"}'
          output = VOSCO::_parseLogOutput.call {}, input
          assert.deepEqual output, [{foo: 'bar'}, {bar: 'baz'}]

      describe '_parseBlameOutput', ->
        it "should parse and return blame output", ->
          input = 'test input'
          output = VOSCO::_parseBlameOutput.call {}, input
          assert.equal typeof output.lines, 'object'
          assert.equal typeof output.commits, 'object'

      describe '_parseBranchOutput', ->
        it "should parse and return branch output", ->
          input = '* current\n  another'
          await VOSCO::_parseBranchOutput.call {}, input, defer(err, list, cur)
          assert.deepEqual list, ['current', 'another']
          assert.equal cur, 'current'
