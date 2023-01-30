#!/usr/bin/python3
import subprocess
import os


def _run(command) -> str:
    return (
        subprocess.run(command, capture_output=True, check=True)
        .stdout
        .decode('utf-8')
        .strip()
    )


def main():
    personal_user_email = os.environ['GIT_PERSONAL_USER_EMAIL']
    organization_user_email = os.environ['GIT_ORGANIZATION_USER_EMAIL']
    personal_user_name = os.environ['GIT_PERSONAL_USER_NAME']
    organization_user_name = os.environ['GIT_ORGANIZATION_USER_NAME']
    organization_name = os.environ['GIT_ORGANIZATION_NAME']
    current_name = _run(['git', 'config', 'user.name'])
    current_email = _run(['git', 'config', 'user.email'])
    remotes = _run(['git', 'remote', '-v']).split('\n')

    is_organization_repo = any(
        organization_name in remote
        for remote in remotes
    )
    if is_organization_repo:
        assert current_name == organization_user_name, \
            "expected organization name: " + organization_user_name
        assert current_email == organization_user_email, \
            "expected organization email: " + organization_user_email
    else:
        assert current_name == personal_user_name, \
            "expected personal name: " + personal_user_name
        assert current_email == personal_user_email, \
            "expected personal email: " + personal_user_email

if __name__ == '__main__':
    main()

