#!/usr/bin/env bash

sqlfluff lint -f yaml "$@" |
    yq '.[] | .filepath + ":" + (.violations.[] | (.start_line_no + ":" + .start_line_pos + ":" + .description))'
