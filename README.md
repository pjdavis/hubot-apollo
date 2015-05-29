# Hubot Apollo Adapter

## Description

This is the Apollo adapter for Hubot.

## Installation & Setup

    % npm install -g hubot coffee-script
    % hubot --create myhubot
    % cd myhubot
    % npm install --save hubot-apollo

**Note**: The default hubot configuration will use a redis based brain that assumes the redis server is already running.  Either start your local redis server (usually with `redis-start &`) or remove the `redis-brain.coffee` script from the default `hubot-scripts.json` file.

