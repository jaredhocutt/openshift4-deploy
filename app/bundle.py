#!/usr/bin/env python3

import logging
import os
import subprocess

from . import BASE_DIR, OpenShiftBase, slugify


logger = logging.getLogger(__name__)


class OpenShiftBundle(OpenShiftBase):
    def __init__(self, vars_file, bundle_dir=None):
        super().__init__(vars_file)

        # Capture bundle directory structure
        if bundle_dir:
            self.bundle_dir = os.path.join(bundle_dir, self.openshift_version)
        else:
            self.bundle_dir = os.path.join(BASE_DIR, 'bundle', self.openshift_version)
        self.bundle_dirs = {
            'images': os.path.join(self.bundle_dir, 'images'),
            'release': os.path.join(self.bundle_dir, 'release'),
            'rhcos': os.path.join(self.bundle_dir, 'rhcos'),
        }

        self.container_volumes = [
            (self.bundle_dir, '/mnt/bundle'),
        ]

        self.required_images = [
            'docker.io/library/registry:2',
            self.container_image,
        ]

    def _export_required_images(self):
        """
        Export the required images.
        """
        for image in self.required_images:
            image_archive_filename = os.path.join(
                self.bundle_dirs['images'],
                '{}.tar'.format(slugify(image))
            )

            if not os.path.exists(image_archive_filename):
                logger.info('Exporting {}'.format(image))

                if image.startswith('localhost'):
                    subprocess.call([
                        'podman',
                        'save',
                        '--format', 'docker-archive',
                        '--output', image_archive_filename,
                        image
                    ])
                else:
                    subprocess.call([
                        'skopeo',
                        'copy',
                        'docker://{}'.format(image),
                        'docker-archive:{}'.format(image_archive_filename)
                    ])

                logging.info('Exported image to {}'.format(
                    image_archive_filename))
            else:
                logger.info('{} already exported to {}'.format(
                    image, image_archive_filename))

        logger.debug('Exporting required images complete')

    def _export_release(self, playbook_args=[]):
        """
        Execute playbook to export release images.
        """
        logger.info('Run playbook to export release images')

        subprocess.call(
            self._playbook_run_command(
                'playbooks/export_release.yml',
                playbook_args=playbook_args,
                volumes=self.container_volumes,
            )
        )

        logger.debug('Playbook to export release images complete')

    def _export_rhcos(self, playbook_args=[]):
        """
        Execute playbook to export RHCOS.
        """
        logger.info('Run playbook to export RHCOS')

        subprocess.call(
            self._playbook_run_command(
                'playbooks/export_rhcos.yml',
                playbook_args=playbook_args,
                volumes=self.container_volumes,
            )
        )

        logger.debug('Playbook to export RHCOS complete')

    def _export_create_tar(self):
        """
        Create tar file of bundle
        """
        logger.info('Create tar file of bundle content')

        cmd = [
            'tar',
            '--directory', self.bundle_dir,
            '--create',
            '--verbose',
            '--file', os.path.join(
                self.bundle_dir,
                'bundle.tar'
            ),
        ] + [os.path.basename(i) for i in self.bundle_dirs.values()]

        subprocess.call(cmd)

        logger.debug('Creating tar file of bundle content complete')

    def export_bundle(self, playbook_args=[]):
        """
        Export bundle content for an air-gapped cluster.
        """
        self._build_container_if_needed()

        # Create directory structure required for export
        logger.debug('Creating bundle directory structure')
        for i in self.bundle_dirs.values():
            os.makedirs(i, mode=0o755, exist_ok=True)

        self._export_required_images()
        self._export_release(playbook_args)
        self._export_rhcos(playbook_args)
        self._export_create_tar()

        print()
        print('The bundle has completed exporting. You can find the bundle at:')
        print()
        print(os.path.join(self.bundle_dir, 'bundle.tar'))
        print()

    def import_bundle(self, bundle_file, playbook_args=[]):
        """
        Import bundle content for an air-gapped cluster.
        """
        pass
