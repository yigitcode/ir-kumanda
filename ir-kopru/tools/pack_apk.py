"""Add classes.dex to the aapt2 base APK while keeping each entry's compression
(resources.arsc must stay STORED for Android 11+)."""
import sys
import zipfile


def main(base_apk: str, dex_path: str, out_apk: str) -> None:
    with zipfile.ZipFile(base_apk) as src, zipfile.ZipFile(out_apk, "w") as dst:
        for info in src.infolist():
            dst.writestr(info, src.read(info.filename))
        dst.write(dex_path, "classes.dex", compress_type=zipfile.ZIP_DEFLATED)


if __name__ == "__main__":
    main(*sys.argv[1:4])
