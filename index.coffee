async  = require "async"
path   = require "path"
{exec} = require "child_process"

# Constructor
VOSCO = (@path) ->
  @author = process.env.USER
  @email = "#{process.env.USER}@#{process.env.HOSTNAME}"
  return @

VOSCO.template = path.resolve __dirname, 'template'
VOSCO.format = '\'{"commit": "%H", "author": "%an", "email": "%ae", "date": "%ad", "message": "%s"}\''

VOSCO::log = (count, callback) ->
  cmd = "log --pretty=format:#{VOSCO.format} --all -#{count}"
  @exec cmd, (error, stdout, stderr) =>
    # TODO Handle Errors
    lines = stdout.split("\n")
    result = []
    lines.forEach (line) ->
      try result.push JSON.parse(line)
    callback null, result

VOSCO::commit = (message, callback) ->
  @exec "add --all .", =>
    @exec "commit -m \"#{message}\"", =>
      # TODO Handle Errors
      callback null

VOSCO::install = (callback) ->
  @exec "init --template #{VOSCO.template}", =>
    @_copyGitignore =>
      @exec "add .gitignore", =>
        @exec "commit -m 'Initial Commit'", =>
          # TODO Handle Errors
          callback null

VOSCO::uninstall = (callback) ->
  exec "rm -rf #{@_getRepositoryDir()}", =>
    # TODO Handle Errors
    callback null

VOSCO::exec = (cmd, callback) ->
  options = {cwd: @path, env: @_getEnv()}
  exec "git #{cmd}", options, callback

VOSCO::._getRepositoryDir = ->
  path.resolve @path, '.vosco'

VOSCO::._getTemplateDir = ->
  path.resolve __dirname, 'template'

VOSCO::_getEnv = ->
  GIT_DIR: @_getRepositoryDir()
  GIT_WORK_TREE: @path
  GIT_AUTHOR_NAME: @author
  GIT_AUTHOR_EMAIL: @email
  GIT_COMMITTER_NAME: @author
  GIT_COMMITTER_EMAIL: @email

VOSCO::_copyGitignore = (callback) ->
  gitignoreSrc = path.join VOSCO.template, "gitignore.txt"
  gitignoreDst = path.join @path, ".gitignore"
  exec "cp #{gitignoreSrc} #{gitignoreDst}", ->
    callback null

# Export
module.exports = VOSCO
