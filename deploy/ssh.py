#!/usr/bin/env python3

import argparse
import json
import subprocess

import yaml


SUPPORTED_CLOUDS = [
    'aws',
    'aws_govcloud',
]


def bastion_ip_aws(cluster_id):
    output = subprocess.check_output([
        'aws',
        'ec2',
        'describe-addresses',
        '--filters',
        'Name=tag:OpenShiftCluster,Values={}'.format(cluster_id),
        'Name=tag:OpenShiftRole,Values=bastion',
    ])
    addresses = json.loads(output)

    return addresses['Addresses'][0]['PublicIp']


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--vars-file',
        required=True,
        help='path to your variables file'
    )
    args = parser.parse_args()

    with open(args.vars_file, 'r') as f:
        data = yaml.load(f.read(), Loader=yaml.SafeLoader)

    # Determine the SSh user
    if data['cloud'] in ['aws', 'aws_govcloud']:
        ssh_user = 'ec2-user'
        bastion_ip = bastion_ip_aws(
            '{}.{}'.format(data['cluster_name'], data['base_domain'])
        )
    else:
        print('\n'.join([
            'You must specify a cloud from the options below:',
            '',
            '\n'.join('  - {}'.format(i) for i in SUPPORTED_CLOUDS),
        ]))
        exit(1)

    subprocess.call([
        'ssh',
        '-i', data['keypair_path'],
        '{}@{}'.format(ssh_user, bastion_ip),
    ])
