#!/usr/bin/env python3

import argparse
import os
# import urllib
from urllib.request import urlopen
import json
import subprocess
import sys
import re
import shutil
import tomllib
import multiprocessing
from pathlib import Path
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class SemanticVersion:
    major: int
    minor: int
    patch: int

    @staticmethod
    def parse(version: str) -> "SemanticVersion":
        major, minor, patch = version.split(".")
        return SemanticVersion(int(major), int(minor), int(patch))

    def __eq__(self, other: "SemanticVersion") -> bool:
        return self.major == other.major and self.minor == other.minor and self.patch == other.patch

    def __lt__(self, other: "SemanticVersion") -> bool:
        return self.major < other.major or self.minor < other.minor or self.patch < other.patch

@dataclass(frozen=True, slots=True)
class Crate:
    name: str
    version: SemanticVersion

def main() -> int:
    prog: str = os.path.basename(__file__)
    parser = argparse.ArgumentParser(prog=prog, description="Update dependencies in Cargo.toml")
    # parser.add_argument("")

    args = parser.parse_args()

    ENDPOINT: str = "https://crates.io/api/v1"

    cargo_toml = Path("Cargo.toml")
    if not cargo_toml.exists():
        print("Cargo.toml does not exist")
        return 1

    # Parse TOML of Cargo.toml


    cargo_toml_contents = tomllib.load(open(cargo_toml, "rb"))

    print(f"{cargo_toml_contents = }")

    dependencies: dict | None = cargo_toml_contents.get("dependencies")
    if dependencies is None:
        print("No dependencies found")
        return 1

    dev_dependencies: dict | None = cargo_toml_contents.get("dev-dependencies")
    if dev_dependencies is None:
        print("No dev-dependencies found")
        # return 1
    crates: list[Crate] = []
    for name, value in dependencies.items():
        if isinstance(value, str):
            semver = SemanticVersion.parse(value)
        else:
            semver = SemanticVersion.parse(value["version"])
        crate = Crate(name, semver)
        crates.append(crate)
        # print(f"{name = }, {semver = }")

    print(f"{crates = }")

    for crate in crates:
        url = f"{ENDPOINT}/crates/{crate.name}"
        print(f"{url = }")
        with urlopen(url) as response:
            data = json.load(response)
            # print(f"{data = }")
            # max_version: int = data["crate"]["max_version"]
            # max_stable_version: int = data["crate"]["max_stable_version"]
            newest_version: int = data["crate"]["newest_version"]
            newest_version: SemanticVersion = SemanticVersion.parse(newest_version)
            print(f"{newest_version = }")

            if

            # latest_version = data["crate"]["newest_version"]
            # print(f"{max_version = }")

    return 0


if __name__ == "__main__":
    sys.exit(main())
