#!/usr/bin/env python3

import os
import subprocess

from .helper import BASE_DIR, ContainerRuntimeMissingError


SUPPORTED_CONTAINER_RUNTIMES = ['podman', 'docker']


class OpenShiftDeploy(object):
    def __init__(self, skip_update=False):
        self.skip_update = skip_update

        self.user_home_dir = self._user_home_dir()
        self.ssh_keys_dir = self._ssh_keys_dir()
        self.aws_credentials_dir = self._aws_credentials_dir()

        self.container_runtime = self._container_runtime()
        self.container_image = 'quay.io/jaredhocutt/openshift4-deploy:latest'
        self.container_run_command = self._container_run_command()

    def _user_home_dir(self):
        """
        The home directory to the actual user, even when run using sudo.
        """
        user = os.environ.get('SUDO_USER', os.environ['USER'])

        return os.path.expanduser('~{}'.format(user))

    def _ssh_keys_dir(self):
        """
        The SSH keys directory for the user.
        """
        return '{}/.ssh'.format(self.user_home_dir)

    def _aws_credentials_dir(self):
        """
        The AWS credentials directory for the user.
        """
        return '{}/.aws'.format(self.user_home_dir)

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

    def _container_run_command(self):
        """
        The container run command with the common options already specified.
        """
        cmd = [
            self.container_runtime,
            'run',
            '--interactive',
            '--tty',
            '--rm',
            '--pull', 'always' if not self.skip_update else 'missing',
            '--hostname', 'openshift4-deploy',
            '--security-opt', 'label=disable',
            '--volume', '{}:/root/.ssh'.format(self.ssh_keys_dir),
            '--volume', '{}:/root/.aws'.format(self.aws_credentials_dir),
            '--volume', '{}:/app'.format(BASE_DIR),
        ]

        # Inject environment variables from host that are used for running the
        # automation
        for key, value in os.environ.items():
            if key.startswith('AWS_'):
                cmd.extend(['--env', '{}={}'.format(key, value)])

        cmd.append(self.container_image)
        return cmd

    def _playbook_run_command(self, playbook, vars_file, playbook_args=[]):
        cmd = self.container_run_command + [
            'ansible-playbook', playbook,
            '-e', '@{}'.format(self._container_file_realpath(vars_file)),
        ] + playbook_args

        return cmd

    def shell(self):
        """
        Open a shell inside the environment.
        """
        subprocess.call(self.container_run_command)

    def create(self, vars_file, playbook_args=[]):
        """
        Create the cluster.
        """
        subprocess.call(
            self._playbook_run_command(
                'playbooks/create_cluster.yml',
                vars_file,
                playbook_args,
            )
        )

    def destroy(self, vars_file, playbook_args=[]):
        """
        Destroy the cluster.
        """
        subprocess.call(
            self._playbook_run_command(
                'playbooks/destroy_cluster.yml',
                vars_file,
                playbook_args,
            )
        )

    def start(self, vars_file, playbook_args=[]):
        """
        Start the machines in the cluster.
        """
        subprocess.call(
            self._playbook_run_command(
                'playbooks/start_cluster.yml',
                vars_file,
                playbook_args,
            )
        )

    def stop(self, vars_file, playbook_args=[]):
        """
        Stop the machines in the cluster.
        """
        subprocess.call(
            self._playbook_run_command(
                'playbooks/stop_cluster.yml',
                vars_file,
                playbook_args,
            )
        )

    def info(self, vars_file, playbook_args=[]):
        """
        Info about the cluster.
        """
        subprocess.call(
            self._playbook_run_command(
                'playbooks/cluster_info.yml',
                vars_file,
                playbook_args,
            )
        )

    def ssh(self, vars_file):
        """
        SSH into the bastion for the cluster.
        """
        cmd = self.container_run_command + [
            'python3',
            os.path.join('/app', 'deploy', 'ssh.py'),
            '--vars-file', self._container_file_realpath(vars_file),
        ]
        subprocess.call(cmd)
