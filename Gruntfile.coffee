"use strict"
module.exports = (grunt) ->

  # Load all grunt tasks
  require("matchdep").filterDev("grunt-*").forEach grunt.loadNpmTasks

  # Track tasks load time
  require("time-grunt") grunt

  # Project configurations
  grunt.initConfig
    config:
      cfg: grunt.file.readYAML("_config.yml")
      var: grunt.file.readYAML("./_app/_data/var.yml")
      pkg: grunt.file.readJSON("package.json")
      app: "<%= config.cfg.source %>"
      dist: "<%= config.cfg.destination %>"
      banner: do ->
        banner = "<!--\n"
        banner += " © <%= config.pkg.author %>.\n\n"
        banner += " <%= config.pkg.name %> - v<%= config.pkg.version %> (<%= grunt.template.today('mm-dd-yyyy') %>)\n"
        # banner += " <%= config.pkg.homepage %>\n"
        banner += " <%= config.pkg.licenses.type %> - <%= config.pkg.licenses.url %>\n"
        banner += " -->"
        banner

    coffeelint:
      options:
        indentation: 2
        no_stand_alone_at:
          level: "error"
        no_empty_param_list:
          level: "error"
        max_line_length:
          level: "ignore"

      test:
        src: ["Gruntfile.coffee"]

    csslint:
      options:
        csslintrc: "<%= config.app %>/assets/less/.csslintrc"

      test:
        src: ["<%= config.app %>/assets/css/app.css"]

    validation:
      options:
        reset: true
        charset: "utf-8"
        doctype: "HTML5"
        relaxerror: [
          "Bad value X-UA-Compatible for attribute http-equiv on element meta."
          "An img element must have an alt attribute, except under certain conditions. For details, consult guidance on providing text alternatives for images."
        ]
      dist:
        src: ["<%= config.dist %>/**/*.html"]

    watch:
      coffee:
        files: ["<%= coffeelint.test.src %>"]
        tasks: ["coffeelint"]

      less:
        files: ["<%= config.app %>/assets/less/**/*.less"]
        tasks: ["less:server", "autoprefixer", "csslint"]

    less:
      server:
        options:
          strictMath: true
          sourceMap: true
          outputSourceFiles: true
          sourceMapURL: "app.css.map"
          sourceMapFilename: "<%= config.app %>/assets/css/app.css.map"

        src: ["<%= config.app %>/assets/less/app.less"]
        dest: "<%= config.app %>/assets/css/app.css"

      dist:
        src: ["<%= less.server.src %>"]
        dest: "<%= less.server.dest %>"

    autoprefixer:
      dist:
        src: ["<%= less.server.dest %>"]
        dest: "<%= less.server.dest %>"

    csscomb:
      options:
        config: "<%= config.app %>/assets/less/.csscomb.json"

      dist:
        src: ["<%= less.server.dest %>"]
        dest: "<%= less.server.dest %>"

    htmlmin:
      dist:
        options:
          removeComments: true
          removeCommentsFromCDATA: true
          removeCDATASectionsFromCDATA: true
          collapseWhitespace: true
          collapseBooleanAttributes: true
          removeAttributeQuotes: true
          removeRedundantAttributes: true
          useShortDoctype: false
          removeEmptyAttributes: true
          removeOptionalTags: true
          removeEmptyElements: false
          lint: false
          keepClosingSlash: false
          caseSensitive: true
          minifyJS: true
          minifyCSS: true

        files: [
          expand: true
          cwd: "<%= config.dist %>"
          src: "**/*.html"
          dest: "<%= config.dist %>/"
        ]

    xmlmin:
      dist:
        files: [
          expand: true
          cwd: "<%= config.dist %>"
          src: "**/*.xml"
          dest: "<%= config.dist %>/"
        ]

    cssmin:
      dist:
        options:
          report: "gzip"

        files: [
          expand: true
          cwd: "<%= config.dist %>/assets/css/"
          src: ["*.css", "!*.min.css"]
          dest: "<%= config.dist %>/assets/css/"
        ]

      # html:
      #   expand: true
      #   cwd: "<%= config.dist %>"
      #   src: "**/*.html"
      #   dest: "<%= config.dist %>"

    rev:
      options:
        encoding: "utf8"
        algorithm: "md5"
        length: 6

      files:
        src: ["<%= config.dist %>/assets/**/*.{js,css,png,jpg,gif,woff}"]

    useminPrepare:
      html: "<%= config.dist %>/index.html"

    usemin:
      options:
        assetsDirs: ["<%= config.dist %>"]

      html: ["<%= config.dist %>/**/*.html"]
      css: ["<%= config.dist %>/assets/css/*.css"]

    smoosher:
      options:
        jsDir: "<%= config.dist %>"
        cssDir: "<%= config.dist %>"

      dist:
        files: [
          expand: true
          cwd: "<%= config.dist %>"
          src: "**/*.html"
          dest: "<%= config.dist %>/"
        ]

    usebanner:
      options:
        position: "bottom"
        banner: "<%= config.banner %>"

      dist:
        files:
          src: ["<%= config.dist %>/**/*.html"]

    shell:
      options:
        stdout: true

      server:
        command: "jekyll serve --watch --future"

      dist:
        command: "jekyll build"

      archive:
        command: "jekyll build -d <%= config.cfg.destination %><%= config.var.base %>/"

      sync:
        command: "rsync -avz --delete --progress <%= config.var.ignore_files %> <%= config.dist %>/ <%= config.var.remote_host %>:<%= config.var.remote_dir %> > rsync.log"

      s3:
        command: "s3cmd sync -rP --guess-mime-type --delete-removed --no-preserve --cf-invalidate --exclude '.DS_Store' <%= config.var.static_files %> <%= config.var.s3_bucket %>"

    concurrent:
      options:
        logConcurrentOutput: true

      server:
        tasks: ["shell:server", "watch"]

      dist:
        tasks: ["htmlmin", "xmlmin", "cssmin"]

    clean:
      dist:
        src: [".tmp", "<%= config.dist %>"]

      postDist:
        src: ["<%= config.dist %>/assets/css/", "<%= config.dist %>/assets/js/"]

    cleanempty:
      dist:
        src: ["<%= config.dist %>/**/*"]

  # Fire up a server on local machine for development
  grunt.registerTask "serve", [
      "clean"
    , "concurrent:server"
  ]

  # Test task
  grunt.registerTask "test", [
      "build"
    # , "csslint"
    , "validation"
  ]

  # Build site with `jekyll`
  grunt.registerTask "build", [
      "clean"
    , "coffeelint"
    , "useminPrepare"
    , "less:dist"
    , "autoprefixer"
    , "csscomb"
    , "shell:dist"
    , "rev"
    , "usemin"
    , "concurrent:dist"
    , "smoosher"
    , "usebanner"
    , "clean:postDist"
  ]

  # Archive old version with specific URL prefix, all old versions goes to http://sparanoid.com/lab/version/
  grunt.registerTask "archive", [
      "clean"
    , "less:dist"
    , "autoprefixer"
    , "csscomb"
    , "shell:archive"
    , "concurrent:dist"
  ]

  # Build site + rsync static files to remote server
  grunt.registerTask "sync", [
      "build"
    , "shell:sync"
  ]

  # Sync image assets with `s3cmd`
  grunt.registerTask "s3", ["shell:s3"]

  # Default task aka. build task
  grunt.registerTask "default", ["build"]
