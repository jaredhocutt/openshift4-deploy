#!/usr/bin/env python3

import argparse
import os


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class ContainerRuntimeMissingError(Exception):
    pass


class OpenShiftDeployHelper(object):
    @staticmethod
    def file_exists(value):
        if not os.path.isfile(value):
            raise argparse.ArgumentTypeError('The path {} does not exist'.format(value))
        return value
