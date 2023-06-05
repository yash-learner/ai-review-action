#!/bin/sh -l

ruby /entrypoint.rb

output=$(cat /tmp/output.json)

echo "::set-output name=result::$output"
