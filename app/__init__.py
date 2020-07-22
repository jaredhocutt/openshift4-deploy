#!/usr/bin/env python3

import argparse
import json
import logging
import os
import re
import subprocess
import unicodedata
from urllib.error import URLError
from urllib.request import urlopen


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SUPPORTED_CONTAINER_RUNTIMES = ['podman', 'docker']


logger = logging.getLogger(__name__)


def file_exists(value):
    """
    Checks if file exists.
    """
    if not os.path.isfile(value):
        raise argparse.ArgumentTypeError('The path {} does not exist'.format(value))
    return value


def slugify(value):
    """
    Converts the value to a string that would be a valid filename.
    """
    value = unicodedata.normalize('NFKD', str(value)).encode(
        'ascii', 'ignore').decode('ascii')
    value = re.sub(r'[/:\.]+', '-', value)
    value = re.sub(r'[^\w\s-]', '', value).strip().lower()
    value = re.sub(r'[-\s]+', '-', value)
    return value


class ContainerRuntimeMissingError(Exception):
    pass


class MissingOpenShiftVersionError(Exception):
    pass


class OpenShiftBase(object):
    def __init__(self, vars_file):
        self.vars_file = vars_file
        self.openshift_version = self._openshift_version()

        # Capture paths of required directories
        self.user_home_dir = os.path.expanduser(
            '~{}'.format(os.environ.get('SUDO_USER', os.environ['USER'])))
        self.ssh_keys_dir = '{}/.ssh'.format(self.user_home_dir)
        self.aws_credentials_dir = '{}/.aws'.format(self.user_home_dir)

        # Capture container details
        self.container_runtime = self._container_runtime()
        self.container_image = 'localhost/openshift4-deploy:{}'.format(
            self.openshift_version)

        self._build_container_if_needed()

    def _container_file_realpath(self, vars_file):
        """
        The real path to the file inside of the container.
        """
        return os.path.realpath(vars_file).replace(BASE_DIR, '/app')

    def _container_runtime(self):
        """
        The container runtime to use.
        """
        for runtime in SUPPORTED_CONTAINER_RUNTIMES:
            try:
                subprocess.call([runtime, '--version'],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE)
                return runtime
            except OSError:
                pass

        raise ContainerRuntimeMissingError()

    def _container_run_command(self, volumes=[]):
        """
        The container run command with the common options already specified.
        """
        os.makedirs(self.ssh_keys_dir, mode=0o700, exist_ok=True)
        os.makedirs(self.aws_credentials_dir, mode=0o755, exist_ok=True)

        cmd = [
            self.container_runtime,
            'run',
            '--interactive',
            '--tty',
            '--rm',
            '--hostname', 'openshift4-bundle',
            '--security-opt', 'label=disable',
            '--volume', '{}:/root/.ssh'.format(self.ssh_keys_dir),
            '--volume', '{}:/root/.aws'.format(self.aws_credentials_dir),
            '--volume', '{}:/app'.format(BASE_DIR),
        ]

        for volume in volumes:
            cmd.extend(['--volume', '{}:{}'.format(volume[0], volume[1])])

        # Inject environment variables from host that are used for running the
        # automation
        for key, value in os.environ.items():
            if key.startswith('AWS_'):
                cmd.extend(['--env', '{}={}'.format(key, value)])

        cmd.append(self.container_image)
        return cmd

    def _playbook_run_command(self, playbook, playbook_args=[], volumes=[]):
        """
        Generate the command to run a playbook.
        """
        cmd = self._container_run_command(volumes=volumes) + [
            'ansible-playbook', playbook,
            '-e', '@{}'.format(self._container_file_realpath(self.vars_file)),
        ] + playbook_args

        return cmd

    def _build_container_if_needed(self):
        """
        Check if the container has been built and build it if not.
        """
        images = subprocess.check_output(
            [
                self.container_runtime,
                'images',
                self.container_image,
                '--format', 'json',
            ]
        )

        # If the list of images has a length of 0, then the image doesn't exist
        if len(json.loads(images)) == 0:
            logger.warn(
                'The container does not exist: {}'.format(self.container_image)
            )

            # Check if we're in a connected environment and can build the iamge
            try:
                urlopen('https://api.openshift.com/', timeout=5)
            except URLError:
                logger.error('You are not connected to the internet.')
                logger.error(
                    'Please import the {} container and retry.'.format(
                        self.container_image))
                exit(1)

            logger.info('Building the container')
            self.build()
            logger.info('Finished building the container')

    def _openshift_version(self):
        """
        Parse the OpenShift version from the variables file.
        """
        logger.debug('Parsing OpenShift version from {}'.format(
            self.vars_file))

        with open(self.vars_file, 'r') as f:
            m = re.search(
                r'^openshift_version:\s+(\S+)',
                f.read(),
                re.MULTILINE
            )

        if m is None:
            raise MissingOpenShiftVersionError()

        openshift_version = m.group(1)
        logger.debug('OpenShift version is {}'.format(openshift_version))

        return openshift_version

    def build(self):
        """
        Build the container image.
        """
        logger.info('Building the container image')

        subprocess.call([
            self.container_runtime,
            'build',
            '--layers',
            '--tag', self.container_image,
            '--build-arg', 'OPENSHIFT_VERSION={}'.format(
                self.openshift_version),
            BASE_DIR,
        ])

        logger.info('Container image built')
