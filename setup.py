#!/usr/bin/env python3

try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

setup(
    name="ANECompat",
    version="0.2.0",
    author="Kacper Rączy",
    author_email="gfw.kra@gmail.com",
    url = "https://github.com/fredyshox/ANECompat",
    description="Python bindings for ANECompat library",
    license="MIT",
    py_modules=["anecompat"],
    package_dir={"": "python"},
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: MacOS",
    ]
)