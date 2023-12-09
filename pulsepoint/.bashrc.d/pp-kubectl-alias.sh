#!/bin/bash

# kubectl reporting-api aliases
alias kure="kubectl --context dm-dev -n rapi-regression"
alias kupr="kubectl --context dm-dev -n rapi-prerelease"
alias kuqa="kubectl --context dm-dev -n rapi-qa"
alias kupd="kubectl --context dm-prod -n reporting-api"

# patch aliases to make completion work
complete -F _complete_alias kure
complete -F _complete_alias kupr
complete -F _complete_alias kuqa
complete -F _complete_alias kupd

