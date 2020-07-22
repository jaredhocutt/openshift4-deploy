#!/usr/bin/env python3

import logging
import os
import subprocess

from . import BASE_DIR, OpenShiftBase


logger = logging.getLogger(__name__)


class OpenShiftDeploy(OpenShiftBase):
    def __init__(self, vars_file):
        super().__init__(vars_file=vars_file)

    def shell(self):
        """
        Open a shell inside the container environment.
        """
        logger.debug('Opening shell inside container environment')
        subprocess.call(
            self._container_run_command() + [
                'bash',
            ]
        )

    def create(self, playbook_args=[]):
        """
        Create the cluster.
        """
        logger.debug('Running playbook to create cluster')
        subprocess.call(
            self._playbook_run_command(
                'playbooks/create_cluster.yml',
                playbook_args=playbook_args,
            )
        )

    def destroy(self, playbook_args=[]):
        """
        Destroy the cluster.
        """
        logger.debug('Running playbook to destroy cluster')
        subprocess.call(
            self._playbook_run_command(
                'playbooks/destroy_cluster.yml',
                playbook_args=playbook_args,
            )
        )

    def start(self, playbook_args=[]):
        """
        Start the machines in the cluster.
        """
        logger.debug('Running playbook to start cluster')
        subprocess.call(
            self._playbook_run_command(
                'playbooks/start_cluster.yml',
                playbook_args=playbook_args,
            )
        )

    def stop(self, playbook_args=[]):
        """
        Stop the machines in the cluster.
        """
        logger.debug('Running playbook to stop cluster')
        subprocess.call(
            self._playbook_run_command(
                'playbooks/stop_cluster.yml',
                playbook_args=playbook_args,
            )
        )

    def info(self, playbook_args=[]):
        """
        Info about the cluster.
        """
        logger.debug('Running playbook to display cluster info')
        subprocess.call(
            self._playbook_run_command(
                'playbooks/cluster_info.yml',
                playbook_args=playbook_args,
            )
        )

    def ssh(self):
        """
        SSH into the bastion for the cluster.
        """
        logger.debug('Creating SSH connection to bastion')
        cmd = self._container_run_command() + [
            'python3',
            os.path.join('/app', 'deploy', 'ssh.py'),
            '--vars-file', self._container_file_realpath(self.vars_file),
        ]
        subprocess.call(cmd)
