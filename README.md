# QR Enabled Jigsaw Puzzle

Welcome to qr enabled jigsaw puzzle.
This app allows you to scan a bunch of qr codes that (when scanned) trigger the qr code to solve by itself.

[Note]
This app was designed to be run in a 4:3 aspect ratio screen (like an ipad). If you run it on a 16:9 screen, some parts of the puzzle will be cut off.

## Built with:
- terraform 1.4.6
- node v16.15.0 
- npm 8.6.0

## How to run:
- `cd lambda/`
- `npm install`
- `cd ../`
- `terraform init`
- `terraform apply`
- use the terraform output to update the index.html file
- `terraform apply` (to update the lambda with correct api variable)

## Pre-requisites:
- aws account
- node 
- npm
- terraform

## How to access the api:
The terraform output will display the api url. 

The api endpoints are
- /jigsaw (GET) : shows the jigsaw puzzle board
- /puzzle?stall=[stall_id] (GET) : acknowledge the particular puzzle (or stall) to solve

(The stall IDs are configured in the index.html and index.js files)


## Pre-Hosted version
If you'd like to have it prehosted for you, please contact me.