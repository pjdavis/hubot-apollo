# Hubot Apollo Adapter

## Description

This is the Apollo adapter for Hubot.

## Installation & Setup

    % npm install -g yo generator-hubot
    % mkdir myhubot
    % cd myhubot
    % yo hubot

**Note**: The default hubot configuration will use a redis based brain that assumes the redis server is already running.  Either start your local redis server (usually with `redis-start &`) or remove the `redis-brain.coffee` script from the default `hubot-scripts.json` file.

## Running Hubot with the Apollo adapter.

    HUBOT_APOLLO_USER=<name> HUBOT_APOLLO_KEY=<apollo-key> bin/hubot -a apollo
