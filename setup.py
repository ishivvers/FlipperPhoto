# -*- coding:utf-8 -*-

from setuptools import setup, find_packages
from codecs import open
from os import path

here = path.abspath(path.dirname(__file__))

setup(
    name='sample',
    version='0.1.0',

    description='Filipenko Photometry Pipeline',
    long_description='',

    url='https://github.com/ishivvers/FlipperPhoto',

    author='UC Berkeley Filippenko Group',
    author_email='ishivvers@berkeley.edu',

    license='BSD',

    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Astronomers',
        'License :: OSI Approved :: BSD License',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.6',
        'Programming Language :: Python :: 2.7',
    ],

    keywords='astronomy photometry',

    packages=find_packages(exclude=['contrib', 'docs', 'tests']),
    install_requires=['future',
        'numpy',
        'astropy',
        'pandas',
        'astroquery'],

    extras_require={
        'dev': ['check-manifest', 'fabric'],
        'test': ['coverage', 'nose'],
    },

    package_data={
        'flipp': ['libs/sextractor_config/*', ],
    },

    entry_points={
        'console_scripts': [
            'flippsolve=flipp.libs.astrometry:flippsolve',
        ],
    },
)
