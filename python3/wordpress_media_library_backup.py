import argparse
import datetime
import os
import re
import sys
import time
import urllib.request
from urllib.parse import urlparse


def get_urls_from_xml(xml_file):
    with open(xml_file, encoding="utf8") as f:
        xml = f.read()
        regex = re.compile("<wp:attachment_url>(.+)<\/wp:attachment_url>", re.MULTILINE)
        matches = regex.findall(xml)

        return matches


def get_filename_and_path_from_url(url):
    url_path = urlparse(url).path.strip("/")
    filename = os.path.basename(url_path)
    dirs = os.path.dirname(url_path).replace("/", os.sep)

    return filename, dirs


def backup(xml_file, destination, overwrite):
    real_path = os.path.realpath(__file__)
    curr_dir = os.path.dirname(real_path)
    urls = get_urls_from_xml(xml_file)

    print("Downloading...")

    for url in urls:
        filename, dirs = get_filename_and_path_from_url(url)
        full_path = os.path.join(curr_dir, destination, dirs)

        print("->", url, end="", flush=True)

        if dirs != "":
            os.makedirs(full_path, exist_ok=True)

        out_file = os.path.join(full_path, filename)

        try:
            response = urllib.request.urlopen(url)

            if os.path.isfile(out_file):
                meta = response.info()
                last_modified = meta.get("Last-Modified")
                meta_modified_time = time.mktime(datetime.datetime.strptime(last_modified, "%a, %d %b %Y %X GMT").timetuple())
                local_file_modified_time = os.path.getmtime(out_file)

                if meta_modified_time > local_file_modified_time:
                    if overwrite:
                        print(" : overwriting", end="", flush=False)
                    else:
                        print(" : skipping", flush=True)
                        continue

            with open(out_file, "wb") as f:
                f.write(response.read())
                print(flush=True)

        except Exception as exc:
            print(exc, ":", url)

    print("Finished.")


def main(args):
    parser = argparse.ArgumentParser(description="Backup media files from wordpress.com site.")
    parser.add_argument("xml_file", type=str, help="The exported XML file.")
    parser.add_argument("destination", type=str, help="The destination directory to save files in.")
    parser.add_argument("-o", "--overwrite", dest="overwrite", action="store_true", help="Overwrite exisiting files. Default value is false.")
    parser.set_defaults(overwrite=False)

    parsed = parser.parse_args()

    backup(parsed.xml_file, parsed.destination, parsed.overwrite)


if __name__ == "__main__":
    main(sys.argv[1:])
