#!/bin/sh

TEMPLATE_DIR=$HOME/.git-templates/

cp -r ./.git-templates/* $TEMPLATE_DIR

git config --global init.templateDir $TEMPLATE_DIR
