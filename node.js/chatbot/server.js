//declare variables and constants using require
var Discord = require('discord.io');
var logger = require('winston');
var mysql = require('mysql');
const config = require('./config.json');
var nodeCleanup = require('node-cleanup');

//declare a global variable for the last message, this will be used in the final callback
//to send the message
var lastMessage = {
  channelID: '',
  assign: function(val){
    this.channelID = val;
    }
}

// Configure logger settings
logger.remove(logger.transports.Console);
logger.add(new logger.transports.Console, {
    colorize: true
});
logger.level = 'info';

// Initialize Discord Bot
const bot = new Discord.Client({
    token: config.discordToken,
    autorun: false,
    messageCacheLimit: 50
});

//connect the bot
bot.connect();

//instantiate the sql connection object
var sqlConn = mysql.createConnection({
  host: config.mysql.host,
  user: config.mysql.user,
  password: config.mysql.password,
  database: config.mysql.database
});
logger.info('SQL Connection object created.');

//connect to the SQL database
sqlConn.connect();


/*                      declare functions                     */

//function to send a message, used as a callback once record data is obtained
function sendMessage(message){
  bot.sendMessage({
      to: lastMessage.channelID,
      message: message
  });
}

//function to check the sql connection state
function checkSqlConnection(sqlConnection){

    if (sqlConnection.state === 'disconnected'){
      return 0;
    } else {
      return 1;
    }

}

//function to get a record from the database
function retrieveRecord(sqlConnection, type, table){

    //check the connection state first and re-connect if necessary
    var state = checkSqlConnection(sqlConnection);
    if (state === 0){
        sqlConnection.connect();
    }

    //execute query
    sqlConnection.query('SELECT ' + type + ' AS record FROM ' + table + ' ORDER BY RAND() LIMIT 1;',
      function (error, results, fields){
            if (error) logger.error('ERROR:' + error);
            var objectKey = Object.keys(results);
            sendMessage(results[objectKey].record);

  });

}

//function to insert a new record into the database
function insertRecord(sqlConnection, type, table, record){

  //check the connection state first and re-connect if necessary
  var state = checkSqlConnection(sqlConnection);
  if (state === 0){
      sqlConnection.connect();
  }

  //execute query
  sqlConnection.query('INSERT INTO ' + table + ' (' + type + ') VALUES ("' + record + '");',
    function (error, results, fields){
          if (error) logger.error('ERROR:' + error);
          var objectKey = Object.keys(results);
          sendMessage("I will learn this " + type + ": " + record );
    });

}

//cleanup function to terminate connections on exit
nodeCleanup(function (exitCode, signal) {

  //disconnect from the database
  sqlConn.end();

  //disconnect the bot
  bot.disconnect();

})

/*                  bot code                                */

//turn the bot on
bot.on('ready', function (evt) {
    logger.info('Connected');
    logger.info('Logged in as: ');
    logger.info(bot.username + ' - (' + bot.id + ')');
});

//set up the handler for on message event
bot.on('message', function (user, userID, channelID, message, evt) {
    // Our bot needs to know if it will execute a command
    // It will listen for messages that will start with `!`
    if (message.substring(0, 1) == '!') {
        var args = message.substring(1).split(' ');
        var cmd = args[0];

        args = args.splice(1);
        switch (cmd) {
            // !ping
            case 'speak':
                lastMessage.assign(channelID, message);
                retrieveRecord(sqlConn, 'quote', config.sqlSpecs.quoteTable);
                break;

            case 'act':
                lastMessage.assign(channelID, message);
                retrieveRecord(sqlConn, 'action', config.sqlSpecs.actionTable);
                break;

            case 'learn-quote':
                lastMessage.assign(channelID, message);
                var lesson = message.replace('!learn-quote','');
                insertRecord(sqlConn, 'quote', config.sqlSpecs.quoteTable, lesson );
                break;

            case 'learn-action':
                lastMessage.assign(channelID, message);
                var lesson = message.replace('!learn-action','');
                insertRecord(sqlConn, 'action', config.sqlSpecs.actionTable, lesson );
                break;

        };
    };
});
