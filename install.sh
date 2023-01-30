#!/bin/sh

TEMPLATE_DIR=$HOME/.git-templates/
mkdir -p $TEMPLATE_DIR

cp -r ./.git-templates/* $TEMPLATE_DIR
find $TEMPLATE_DIR

git config --global init.templateDir $TEMPLATE_DIR
