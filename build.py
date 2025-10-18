import json
import os, io
import shutil
import sys
import tarfile
import time

def get_timestamp():
    return time.strftime('%Y%m%d%H%M', time.localtime())

def get_default_permission(data: str | bytes) -> int:
    # .sh .lua and non extension files need exec permission
    if isinstance(data, str):
        _, ext = os.path.splitext(data)
        if ext in ['.sh', '.lua']:
            return 0o755
    
        f = open(data, 'rb')
    else:
        f = io.BytesIO(data)

    with f:
        header = f.read(2)
        if header == b'#!':
            return 0o755

        header += f.read(2)
        if header == b'\x7FELF':
            return 0o755

    return 0o644

def add_raw(tar: tarfile.TarFile, path: str, data: str | bytes, mode: int | None = None):
    if isinstance(data, str):
        data = data.encode('utf-8')
    fileobj = io.BytesIO(data)
    info = tarfile.TarInfo(name=path)
    info.size = len(data)
    if mode is None:
        mode = get_default_permission(data)
    info.mode = mode
    info.mtime = time.time()
    tar.addfile(tarinfo=info, fileobj=fileobj)

def add_dir(tar: tarfile.TarFile, dir_path: str, dest_path: str, mode: int | None = None):
    for root, _dirs, files in os.walk(dir_path):
        for file in files:
            full_path = os.path.join(root, file)
            arcname = os.path.relpath(full_path, start=dir_path)
            arcname = os.path.join(dest_path, arcname)

            info = tar.gettarinfo(full_path, arcname=arcname)
            if mode is None:
                info.mode = get_default_permission(full_path)
            else:
                info.mode = mode

            with open(full_path, "rb") as f:
                tar.addfile(info, f)

def add_file(tar: tarfile.TarFile, src_path: str, dest_path: str, mode: int | None = None):
    if mode is None:
        mode = get_default_permission(src_path)

    info = tar.gettarinfo(src_path, arcname=dest_path)
    info.mode = mode

    with open(src_path, "rb") as f:
        tar.addfile(info, f)

def build_sigle_plugin(plugin_path: str, output_dir: str, metadata: dict[str, str], arch: str, ts: str):
    if arch == "all":
        full_name = "plugin-{name}-v{version}-Build{timestamp}".format(
            name=metadata["name"],
            version=metadata["version"],
            timestamp=ts
        )
    else:
        full_name = "plugin-{name}-{archs}-v{version}-Build{timestamp}".format(
            name=metadata["name"],
            archs=arch,
            version=metadata["version"],
            timestamp=ts
        )
    
    plugin_meta = {
        "name": metadata["name"],
        "alias": metadata["alias"],
        "manufacturer": metadata["manufacturer"],
        "version": metadata["version"],
        "type": metadata["type"],
        "description": metadata["description"],
        "releasenotes": metadata.get("releasenotes", ""),
        "upgradetype": metadata.get("upgradetype", ""),
    }

    tar_path = os.path.join(output_dir, f"{full_name}.ipk")

    base_dir = '.'

    with tarfile.open(tar_path, "w:gz") as tar:
        add_dir(tar, os.path.join(plugin_path, "html"), f"{base_dir}/html")
        add_file(tar, os.path.join(plugin_path, "logo.png"), f"{base_dir}/html/logo.png")
        add_raw(tar, f"{base_dir}/html/metadata.json", json.dumps(plugin_meta))

        add_dir(tar, os.path.join(plugin_path, "script"), f'{base_dir}/script')
        add_file(tar, os.path.join(plugin_path, "install.sh"), f"{base_dir}/install.sh", mode=0o755)

        bin_dir = os.path.join(plugin_path, "bin")
        if os.path.exists(bin_dir) and os.path.isdir(bin_dir):
            add_dir(tar, bin_dir, f"{base_dir}/bin")

        include = metadata.get("include", [])
        for item in include:
            src_path = os.path.join(plugin_path, item)
            if os.path.exists(src_path):
                if os.path.isdir(src_path):
                    add_dir(tar, src_path, f"{base_dir}/{item}")
                else:
                    add_file(tar, src_path, f"{base_dir}/{item}")
            else:
                print(f"Warning: Included path '{item}' does not exist in plugin directory.", file=sys.stderr)
        
        bins: dict[str, str | dict[str, str] | list[str]] = metadata.get("bin", {})
        if arch in bins:
            bin_files = bins[arch]
            if isinstance(bin_files, dict):
                for src, dest in bin_files.items():
                    src_path = os.path.join(plugin_path, src)
                    dest_path = f"{base_dir}/{dest}"
                    add_file(tar, src_path, dest_path)
            elif isinstance(bin_files, list):
                for file in bin_files:
                    src_path = os.path.join(plugin_path, file)
                    dest_path = os.path.basename(file)
                    add_file(tar, src_path, f"{base_dir}/{dest_path}")
            else:
                src_path = os.path.join(plugin_path, bin_files)
                dest_path = os.path.basename(bin_files)
                add_file(tar, src_path, f"{base_dir}/{dest_path}")

def build_plugin(plugin_path: str, output_dir: str) -> dict[str, str]:
    with open(os.path.join(plugin_path, 'metadata.json'), 'r', encoding='utf-8') as f:
        metadata = json.load(f)
    archs = metadata.get("arch", [])
    if not archs:
        archs = ["all"]
    ts = get_timestamp()
    for arch in archs:
        build_sigle_plugin(plugin_path, output_dir, metadata, arch, ts)
    return {
        "name": metadata["name"],
        "alias": metadata["alias"],
        "manufacturer": metadata["manufacturer"],
        "version": metadata["version"],
        "type": metadata["type"],
        "description": metadata["description"],
        "releasenotes": metadata.get("releasenotes", ""),
        "build": ts,
        "compatibility": archs
    }

def main():
    if len(sys.argv) != 3:
        print("Usage: python build.py <plugin_source_dir> <output_dir>")
        sys.exit(1)
    
    plugin_source_dir = sys.argv[1]
    output_dir = sys.argv[2]

    if not os.path.exists(plugin_source_dir):
        print(f"Error: Plugin source directory '{plugin_source_dir}' does not exist.")
        sys.exit(1)
    
    if os.path.exists(output_dir):
        shutil.rmtree(output_dir)

    os.makedirs(output_dir, exist_ok=True)

    plugin_dir = os.path.join(output_dir, "ipk")
    os.makedirs(plugin_dir, exist_ok=True)

    plugins = []

    logo_tar_gz = tarfile.open(os.path.join(output_dir, "img.tar.gz"), "w:gz")

    for item in os.listdir(plugin_source_dir):
        plugin_path = os.path.join(plugin_source_dir, item)
        if os.path.isdir(plugin_path):
            print(f"Building plugin from '{plugin_path}'...")
            plugin = build_plugin(plugin_path, plugin_dir)
            add_file(logo_tar_gz, os.path.join(plugin_path, "logo.png"), f"./{plugin['name']}.png")
            plugins.append(plugin)
            print(f"Built plugin from '{plugin_path}' successfully.")
    
    logo_tar_gz.close()
    print("All plugins built successfully.")

    with open(os.path.join(output_dir, "plugins.json"), "w", encoding="utf-8") as f:
        json.dump(plugins, f, indent=4, ensure_ascii=False)

if __name__ == "__main__":
    main()