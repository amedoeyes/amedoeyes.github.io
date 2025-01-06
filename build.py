from jinja2 import Environment, FileSystemLoader
import json
import shutil
import sys
import hashlib
from pathlib import Path
from livereload import Server


class Cache:
    def __init__(self, path: Path):
        self._path = path
        self._hashes = {}
        if self._path.exists():
            with open(self._path, "r") as f:
                self._hashes = json.load(f)

    def changed(self, path: Path) -> bool:
        curr_hash = self.calculate_hash(path)
        prev_hash = self._hashes.get(str(path), "")
        if prev_hash == "" or curr_hash != prev_hash:
            self._hashes[str(path)] = curr_hash
            return True
        return False

    def save(self):
        with open(self._path, "w") as f:
            json.dump(self._hashes, f, indent=4)

    @staticmethod
    def calculate_hash(path: Path) -> str:
        hash_sha256 = hashlib.sha256()
        with open(path, "rb") as f:
            while chunk := f.read(8192):
                hash_sha256.update(chunk)
        return hash_sha256.hexdigest()


dirs = {
    "templates": Path("./templates/"),
    "data": Path("./data/"),
    "static": Path("./static/"),
    "build": Path("./build/"),
}


def build():
    build_dir = dirs["build"]
    static_dir = dirs["static"]
    templates_dir = dirs["templates"]
    data_dir = dirs["data"]

    main_file = "main.html"
    data_file = "data.json"
    render_file = "index.html"

    main_path = templates_dir / main_file
    data_path = data_dir / data_file
    render_path = build_dir / render_file

    build_dir.mkdir(parents=True, exist_ok=True)

    cache = Cache(build_dir / ".cache.json")

    if cache.changed(main_path) or cache.changed(data_path):
        with open(data_path, "r") as f:
            data = json.load(f)

        with open(render_path, "w") as f:
            env = Environment(loader=FileSystemLoader(templates_dir))
            template = env.get_template(main_file)
            f.write(template.render(data))
            print(f"Rendered: {main_path} {data_file} -> {render_path}")

    for src in static_dir.rglob("*"):
        if src.is_file() and cache.changed(src):
            dest = build_dir / src.relative_to(static_dir)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dest)
            print(f"Copied: {src} -> {dest}")

    cache.save()


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "watch":
        build()
        server = Server()
        server.watch(dirs["templates"], build)
        server.watch(dirs["data"], build)
        server.watch(dirs["static"], build)
        server.serve(root=dirs["build"], open_url_delay=0)
    else:
        build()


if __name__ == "__main__":
    main()
