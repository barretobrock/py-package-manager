# Sample config file for package

# These are things that should be changed before installation
REPO_NAME = 'servertools'
VENV_NAME = 'stools'
DESC = 'A package for routines performed by my home automation server.'
# Dependencies this package has on any of my other projects.
#   This text gets appended to placeholder in GIT_DEP_URL
MY_DEPS = ['slacktools', 'kavalkilu']


URL_TEMPLATE = 'https://github.com/barretobrock'
DEP_TEMPLATE = f'git+{URL_TEMPLATE}/{{dep}}/tarball/master#egg={{dep}}'

URL = f'{URL_TEMPLATE}/{REPO_NAME}'
GIT_URL = f'git+{URL}.git#egg={REPO_NAME}'
VENV_PATH = f'~/venvs/{VENV_NAME}/bin/python3'


config = {
    'name': REPO_NAME,
    'author': 'bobrock',
    'author_email': 'bobrock@tuta.io',
    'url': URL,
    'dependency_links': [DEP_TEMPLATE.format(dep=x) for x in MY_DEPS]
}
