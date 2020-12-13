"""Setup the module.
Resources to build this:
    https://packaging.python.org/en/latest/distributing.html
    https://github.com/pypa/sampleproject
"""
import versioneer
from setuptools import setup, find_packages
from .config import config_dict


# Arguments that are not included by default in the config.py file
setup_args = {
    'version': versioneer.get_version(),
    'cmdclass': versioneer.get_cmdclass(),
    'packages': find_packages(exclude=['api', 'crons', 'documentation', 'scripts', 'tests']),
    'install_requires': []
}
# Bind these arguments to the config dict
setup_args.update(config_dict)

setup(**setup_args)
