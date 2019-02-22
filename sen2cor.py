#!/usr/bin/env python
import re
# import shutil


def _l2a_name(l1c_name):
    return re.sub("L1C_", "L2A_", l1c_name)


def _tilename(l1c_name):
    return re.findall("_T(.*?)_", l1c_name)[0]


if __name__ == '__main__':

    import os
    import argparse
    import docker

    parser = argparse.ArgumentParser()
    parser.add_argument("-o", "--output", help="Specify output folder")
    parser.add_argument("-a", "--auxdata", help="Specify aux_data folder")
    parser.add_argument("-d", "--dem", help="Specify dem folder")
    parser.add_argument("-l", "--log", help="Specify log folder")
    parser.add_argument("input", help="input filename (*L1C*.SAFE folder)")
    # parser.add_argument("-r", "--resolution", help="set resolution")

    args = parser.parse_args()

    sen2cor_home = "/root/sen2cor/2.5"
    sen2cor_bin = "/sen2cor/Sen2Cor-02.05.05-Linux64/lib/python2.7/site-packages/sen2cor"

    container_aux_data = os.path.join(sen2cor_bin, "aux_data")
    container_dem = os.path.join(sen2cor_home, "dem")
    container_log = os.path.join(sen2cor_home, "log")

    username = os.environ['USER']

    input_folder = os.path.dirname(args.input)
    filename = os.path.basename(args.input)

    # Every process has its own log folder to avoid problems with .progress
    # and .estimation files in the log
    log_folder = os.path.join(args.log, _l2a_name(filename))
    # host_tmp_output = '/home/{}/sen2cor_output'.format(username)
    output_folder = os.path.join(args.output, _tilename(filename))

    volumes = {'{}'.format(input_folder):  {'bind': '/input', 'mode': 'ro'},
               output_folder:  {'bind': '/tmp_l2a', 'mode': 'rw'},
               args.auxdata:  {'bind': container_aux_data, 'mode': 'rw'},
               args.dem: {'bind': container_dem, 'mode': 'rw'},
               log_folder: {'bind': container_log, 'mode': 'rw'}
               }

    client = docker.from_env()
    client.containers.run("redblanket/sen2cor:latest",
                          "{}".format(os.path.join("/input", filename)),
                          auto_remove=True,
                          volumes=volumes)

    # tile_path = os.path.join(args.output, _tilename(filename))
    # if not os.path.isdir(tile_path):
    #     os.makedirs(tile_path)
    #
    # src = os.path.join(host_tmp_output, l2a_name)
    # dst = os.path.join(args.output, _tilename(filename), l2a_name)
    # shutil.copytree(src, dst)
