#!/usr/bin/env node

const program = require('commander');
program
  .version('1.0.0')
  .arguments('<configPath>', 'The folder which contains config file')
  .option('-f, --filter <filter>', 'The filter to apply on config file. Default to "\.cfg$"', '\.cfg$')
  .option('-p, --print', 'Print merged config')
  .option('-o, --output <path>', 'The output file to write merged config')
  .option('-v, --verbose', 'Print logs')
  .action(mergeFiles)
  .parse(process.argv);

if (!process.argv.slice(2).length) {
  program.outputHelp();
}

function mergeFiles(configPath, options) {
  if (options.verbose) {
    console.log('Looking for config files in %s', configPath);
  }

  const path = require('path');
  const fs = require('fs');
  fs.readdir(configPath, 'utf8', function (err, files) {
    if (err) {
      return console.error(err);
    }

    var fileFilterRegexp = new RegExp(options.filter);
    var configEntryRegexp = /^\s+#?/i;

    var globalConfig = files
      .filter(function (file) {
        return file.match(fileFilterRegexp);
      })
      .sort()
      .reduce(function (config, file) {
        if (options.verbose) {
          console.log("Processing file " + file);
        }

        var content = fs.readFileSync(path.join(configPath, file), 'utf8');
        var lines = content.split("\n");

        var section = undefined;
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i];

          if (line.match(configEntryRegexp) || line.length == 0) {
            if (section) {
              config[section].push(line);
            }
          } else {
            section = line;
            if (!config[section]) {
              config[section] = [];
            }
          }
        }
        return config;
      }, {});

    var outputContent = Object.keys(globalConfig).reduce(function (buffer, key) {
      return buffer + key + "\n" + globalConfig[key].join("\n") + "\n";
    }, '');

    if (options.print) {
      console.log(outputContent);
    }
    if (options.output) {
      fs.writeFile(options.output, outputContent, function (err) {
        if (err) {
          return console.error(err);
        }

        if (options.verbose) {
          console.log('Merged file writtent in ' + options.output);
        }
      });
    }
  });
}