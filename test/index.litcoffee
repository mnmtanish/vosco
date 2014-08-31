Requirements
------------

    assert = require "assert"
    fs     = require "fs"
    path   = require "path"
    {exec} = require "child_process"
    async  = require "async"
    VOSCO  = require ".."

VOSCO
-----

    describe "VOSCO", ->

      it "should copy gitignore file to repo path", (finish) ->
        vosco = new VOSCO test_path
        vosco.execEnv.IS_TEST = 1
        vosco._copyGitignore ->
          gitignore = path.join test_path, ".gitignore"
          assert.equal true, fs.existsSync gitignore
          do finish

      it "should list all commits", (finish) ->
        vosco = new VOSCO test_path
        vosco.execEnv.IS_TEST = 1
        createCommit vosco, "test commit", (error, result) ->
          assert.equal true, Array.isArray result
          assert.equal 1, result.length
          assert.equal "test commit", result[0].message
          do finish

      it "should initialize the repository", (finish) ->
        vosco = new VOSCO test_path
        vosco.execEnv.IS_TEST = 1
        vosco.install ->
          vosco.log 10, (error, result) ->
            assert.equal 1, result.length
            assert.equal "Initial Commit", result[0].message
            do finish

      it "should create new commit", (finish) ->
        vosco = new VOSCO test_path
        vosco.execEnv.IS_TEST = 1
        vosco.install ->
          createCommit vosco, "test commit", (error, result) ->
            assert.equal true, Array.isArray result
            assert.equal 2, result.length
            assert.equal "test commit", result[0].message
            do finish

      it "should return blame info", (finish) ->
        vosco = new VOSCO test_path
        vosco.execEnv.IS_TEST = 1
        vosco.install ->
          createCommit vosco, "first commit", (error, result) ->
            firstCommit = result[0].commit
            createCommit vosco, "second commit", (error, result) ->
              secondCommit = result[0].commit
              vosco.blame test_file, (error, result) ->
                assert.equal result[0].commit, firstCommit
                assert.equal result[1].commit, secondCommit
                do finish

      it "should rollback to previous commit", (finish) ->
        vosco = new VOSCO test_path
        vosco.execEnv.IS_TEST = 1
        vosco.install ->
          vosco.log 10, (error, result) ->
            firstCommit = result[0].commit
            createCommit vosco, "test commit", (error, result) ->
              vosco.rollback firstCommit, ->
                vosco.log 10, (error, result) ->
                  assert.equal firstCommit, result[0].commit
                  do finish

Helpers
-------

      test_path = "/tmp/test_repo"
      test_file = "/tmp/test_repo/test.txt"
      repo_path = "/tmp/test_repo/.vosco"

      beforeEach (done) ->
        exec "mkdir #{test_path}", done

      afterEach (done) ->
        exec "rm -rf #{test_path}", done

      createCommit = (vosco, message, callback) ->
        options = {cwd: test_path, env: vosco.execEnv}
        run = (cmd, cb) -> exec cmd, options, (err) -> cb(err)
        async.waterfall [
          (cb) -> run "echo #{Date.now()} >> #{test_file}", cb
          (cb) -> run "git init", cb
          (cb) -> vosco.commit message, (err) -> cb(err)
          (cb) -> vosco.log 5, cb
        ], callback
