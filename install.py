#!/usr/bin/python3
import os
import pathlib
import shutil
import subprocess


def main():
    home = pathlib.Path(os.environ['HOME'])
    templates_dir = home / '.git-templates'
    shutil.copytree('.git-templates', templates_dir, dirs_exist_ok=True)
    subprocess.run(['git', 'config', '--global', 'init.templateDir', templates_dir], check=True)

    organization_name = input('Organization name: ')
    organization_user_name = input('Organization user name: ')
    organization_user_email = input('Organization user email: ')
    personal_user_name = input('Personal user name: ')
    personal_user_email = input('Personal user email: ')
    with open(home / '.bashrc', 'a') as f:
        print('export GIT_ORGANIZATION_NAME="{}"'.format(organization_name), file=f)
        print('export GIT_ORGANIZATION_USER_NAME="{}"'.format(organization_user_name), file=f)
        print('export GIT_ORGANIZATION_USER_EMAIL="{}"'.format(organization_user_email), file=f)
        print('export GIT_PERSONAL_USER_NAME="{}"'.format(personal_user_name), file=f)
        print('export GIT_PERSONAL_USER_EMAIL="{}"'.format(personal_user_email), file=f)


if __name__ == '__main__':
    main()

