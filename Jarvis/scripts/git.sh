#!/bin/bash

echo
echo "+-----------------------------------------------------------------------------------------------------------------------------------+"
echo
echo "⚪ Setting up Git user name and email"
echo

USER_NAME="Ritik Srivastava"
USER_EMAIL="ritik.space@gmail.com"
CURRENT_USER_NAME=$(git config --global user.name)
CURRENT_USER_EMAIL=$(git config --global user.email)

if [ "$CURRENT_USER_NAME" != "$USER_NAME" ]; then
    echo "✔ Setting Git user name to $USER_NAME"
    git config --global user.name "$USER_NAME"
else
    echo "✔ Username already set to $CURRENT_USER_NAME"
fi

if [ "$CURRENT_USER_EMAIL" != "$USER_EMAIL" ]; then
    echo "✔ Setting Git user email to $USER_EMAIL"
    git config --global user.email "$USER_EMAIL"
else
    echo "✔ Email already set to $CURRENT_USER_EMAIL"
fi