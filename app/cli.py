#!/usr/bin/env python3

import argparse
import logging

from . import file_exists


class OpenShiftDeployCLI(object):
    def __init__(self):
        self.parser = argparse.ArgumentParser(
            description=(
                'A tool for deploying OpenShift 4.'
            )
        )
        self.subparsers = self.parser.add_subparsers()
        self.parent_parser = self._parent_parser()

        self.add_subparser_build()
        self.add_subparser_shell()
        self.add_subparser_bundle()
        self.add_subparser_create()
        self.add_subparser_destroy()
        self.add_subparser_start()
        self.add_subparser_stop()
        self.add_subparser_info()
        self.add_subparser_ssh()

    def _parent_parser(self):
        """
        Create parent subparser that contains common parameters to use for any
        subparser that inherets it.
        """
        parser = argparse.ArgumentParser(add_help=False)
        parser.add_argument(
            '--vars-file',
            required=True,
            type=file_exists,
            help='path to your variables file'
        )

        return parser

    def add_subparser(self, name, help='', parents=None):
        """
        Add a subparser that inhertis the parent subparser.
        """
        parser = self.subparsers.add_parser(
            name,
            parents=[self.parent_parser] if parents is None else parents,
            help=help,
        )

        parser.set_defaults(action=name)
        return parser

    def add_subparser_build(self):
        """
        Add subparer for build.
        """
        self.add_subparser(
            'build',
            help='build the container image'
        )

    def add_subparser_shell(self):
        """
        Add subparer for shell.
        """
        self.add_subparser(
            'shell',
            help='open a shell inside of the environment'
        )

    def add_subparser_bundle(self):
        """
        Add subarser for bundle.
        """
        parser = self.add_subparser(
            'bundle',
            help='bundle the content for an air-gapped environment',
            parents=[],
        )
        subparsers = parser.add_subparsers()

        # Add subparser to handle exporting bundle
        subparser_export = subparsers.add_parser(
            'export',
            parents=[
                self.parent_parser,
            ],
            help='export bundle content'
        )
        subparser_export.add_argument(
            '--bundle-dir',
            help='directory to place bundle content'
        )
        subparser_export.set_defaults(bundle_action='export')

        # Add subparser to handle importing bundle
        subparser_import = subparsers.add_parser(
            'import',
            parents=[
                self.parent_parser,
            ],
            help='import bundle content'
        )
        subparser_import.add_argument(
            '--bundle-file',
            required=True,
            help='bundle archive file to unpack'
        )
        subparser_import.add_argument(
            '--bundle-dir',
            help='directory to place bundle content'
        )
        subparser_import.set_defaults(bundle_action='import')

    def add_subparser_create(self):
        """
        Add subparer for create.
        """
        self.add_subparser(
            'create',
            help='create the cluster',
        )

    def add_subparser_destroy(self):
        """
        Add subparer for destroy.
        """
        self.add_subparser(
            'destroy',
            help='destroy the cluster'
        )

    def add_subparser_start(self):
        """
        Add subparer for start.
        """
        self.add_subparser(
            'start',
            help='start the machines in your cluster'
        )

    def add_subparser_stop(self):
        """
        Add subparer for stop.
        """
        self.add_subparser(
            'stop',
            help='stop the machines in your cluster'
        )

    def add_subparser_info(self):
        """
        Add subparer for info.
        """
        self.add_subparser(
            'info',
            help='info about your cluster'
        )

    def add_subparser_ssh(self):
        """
        Add subparer for ssh.
        """
        self.add_subparser(
            'ssh',
            help='ssh into the bastion for your cluster'
        )

    def parse_known_args(self):
        """
        Parse known args and also include undefined args.
        """
        known_args, extra_args = self.parser.parse_known_args()

        if not hasattr(known_args, 'action'):
            self.parser.print_help()
            exit(1)
        return known_args, extra_args
