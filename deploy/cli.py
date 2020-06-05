#!/usr/bin/env python3

import argparse

from .helper import OpenShiftDeployHelper


class OpenShiftDeployCLI(object):
    def __init__(self):
        self.parser = argparse.ArgumentParser()
        self.subparsers = self.parser.add_subparsers()

        self.parent_parser = argparse.ArgumentParser(add_help=False)
        self.parent_parser.add_argument(
            '--skip-update',
            action='store_true',
            help='skip automatic update of the conatiner image'
        )

        self.parent_parser_playbook = argparse.ArgumentParser(add_help=False)
        self.parent_parser_playbook.add_argument(
            '--vars-file',
            required=True,
            type=OpenShiftDeployHelper.file_exists,
            help='path to your variables file'
        )

        self._add_subparser(
            'shell',
            help='open a shell inside of the environment'
        )
        self._add_subparser_playbook(
            'create',
            help='create the cluster',
        )
        self._add_subparser_playbook(
            'destroy',
            help='destroy the cluster'
        )
        self._add_subparser_playbook(
            'start',
            help='start the machines in your cluster'
        )
        self._add_subparser_playbook(
            'stop',
            help='stop the machines in your cluster'
        )
        self._add_subparser_playbook(
            'info',
            help='info about your cluster'
        )
        self._add_subparser_playbook(
            'ssh',
            help='ssh into the bastion for your cluster'
        )

    def _add_subparser(self, name, help=''):
        parser = self.subparsers.add_parser(
            name,
            parents=[
                self.parent_parser,
            ],
            help=help,
        )

        parser.set_defaults(action=name)
        return parser

    def _add_subparser_playbook(self, name, help=''):
        parser = self.subparsers.add_parser(
            name,
            parents=[
                self.parent_parser,
                self.parent_parser_playbook,
            ],
            help=help,
        )

        parser.set_defaults(action=name)
        return parser

    def parse_known_args(self):
        known_args, extra_args = self.parser.parse_known_args()

        if not hasattr(known_args, 'action'):
            self.parser.print_help()
            exit(1)
        return known_args, extra_args
