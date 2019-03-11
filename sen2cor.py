#!/usr/bin/env python
import re
import os
import time
import argparse
import docker
import subprocess
import logging
import signal
import random
import string
import shutil


def _l2a(l1c_name):
    return re.sub("L1C_", "L2A_", l1c_name)


def _tilename(l1c_name):
    return re.findall("_T(.*?)_", l1c_name)[0]


def _user_info(user=None, uid=None, gid=None):
    import pwd
    import grp

    if not user:
        user = os.environ['USER']
    if not uid:
        uid = pwd.getpwnam(user).pw_uid
    if not gid:
        gid = grp.getgrnam(user).gr_gid

    return user, uid, gid


def random_string(n=10):
    return "s2c_" + ''.join(random.choice(string.ascii_letters + string.digits)
                            for _ in range(n))


def _product(l1c_path):

    product_dir, basename = os.path.dirname(l1c_path), os.path.basename(l1c_path)
    product_id, product_type = basename.split('.')

    return product_dir, product_id, product_type


def unzip(filename, dirname):
    # Check if L1C.SAFE exists. Eventually delete and expand again
    filename_safe = filename[:-4] + ".SAFE"
    if os.path.isdir(filename_safe):
        shutil.rmtree(filename_safe)
    print('Unzipping {}'.format(filename))
    subprocess.call("unzip {} -d {}".format(filename, dirname), shell=True)
    print('\n')


def _container_folders():
    # Container paths variables
    # se2cor paths inside the docker container
    sen2cor_home = "/root/sen2cor/2.5"
    sen2cor_bin = "/tmp/sen2cor/Sen2Cor-02.05.05-Linux64/lib/python2.7/site-packages/sen2cor"

    # container folders
    container_input = '/tmp/input'
    container_output = '/tmp/output'
    container_log = os.path.join(sen2cor_home, "log")
    container_aux_data = os.path.join(sen2cor_bin, "aux_data")
    container_dem = os.path.join(sen2cor_home, "dem")

    return container_input, container_output, container_log, container_aux_data, container_dem


class ContainerConfig:
    """Structure to load container paths.
    TODO: Load from json/yaml/config file"""

    sen2cor_home = "/root/sen2cor/2.5"
    sen2cor_bin = "/tmp/sen2cor/Sen2Cor-02.05.05-Linux64/lib/python2.7/site-packages/sen2cor"

    # container folders
    input = '/tmp/input'
    output = '/tmp/output'
    log = os.path.join(sen2cor_home, "log")
    auxdata = os.path.join(sen2cor_bin, "aux_data")
    dem = os.path.join(sen2cor_home, "dem")


def _volumes(l2a_id, product_dir, output_dir, log_dir, auxdata=None, dem=None):
    """ Returns dictionary of mount points for docker volume """
    # check that no mount points overlap
    if len(set([product_dir, output_dir, log_dir])) < 3:
        raise ValueError(" 'product_dir', 'output_dir' and 'log_dir' must be different")

    # host folders to mount on container
    # container_input, container_output, container_log, container_aux_data, container_dem = _container_folders()
    container_cfg = ContainerConfig()

    log_folder = os.path.join(log_dir, l2a_id)

    # volumes dictionary of mounts points
    volumes = {product_dir:  {'bind': container_cfg.input, 'mode': 'ro'},
               output_dir:  {'bind': container_cfg.output, 'mode': 'rw'},
               log_folder: {'bind': container_cfg.log, 'mode': 'rw'}
               }
    if auxdata:
        if not os.path.isdir(auxdata):
            raise ValueError("Mount path given for 'auxdata' folder '{}' does not exists.")
        volumes[auxdata] = {'bind': container_cfg.auxdata, 'mode': 'rw'}
    if dem:
        volumes[dem] = {'bind': container_cfg.dem, 'mode': 'rw'}
        _create_folders(dem)

    # make sure that the needed folders exist
    _create_folders(output_dir, log_folder)

    return volumes


def _create_folders(*folders):
    """ Creates folders if they don't exist"""
    for f in folders:
        if not os.path.isdir(f):
            os.makedirs(f)


def _sen2cor_home_folders(sen2cor_home):
    def f(x): return os.path.join(sen2cor_home, x)
    subfolders = ['log', 'aux_data', 'dem']
    return list(map(f, subfolders))


def sen2cor_docker(sen2cor_image, docker_command, volumes, container_name, uid,
                   gid, use_dockerpy=False):

    if use_dockerpy:
        # TODO testing
        client = docker.from_env()
        container = client.containers.run(sen2cor_image,
                                          docker_command,
                                          name=container_name,
                                          auto_remove=True,
                                          environment=["HOSTUSER_ID={}".format(uid),
                                                       "HOSTGROUP_ID={}".format(gid)],
                                          volumes=volumes)
        return container
    else:
        # use subprocess routine
        cmd = " ".join(["docker run --rm"]
                       + ["--name {}".format(container_name)]
                       + ["-v {}:{}".format(k, v['bind']) for k, v in volumes.items()]
                       + ["-e HOSTUSER_ID={}".format(uid)]
                       + ["-e HOSTGROUP_ID={}".format(gid)]
                       + [sen2cor_image, docker_command]
                       )
        subprocess.call(cmd, shell=True)


def sen2cor(input_path, output_dir, sen2cor_home,
            s2c_options='', sen2cor_image=None, use_dockerpy=False,
            expand_dir=None, uid=None, gid=None):

    # Signal handling - Kill docker container when process is killed
    # generate random name for container
    container_name = random_string(n=10)

    # Do not put any output to stderr/stdout here as this will crash the
    # handler (so no print statements)
    def handle_signal(signal, frame):
        if use_dockerpy:
            container.kill()
        else:
            kill_cmd = "docker kill {}".format(container_name)
            subprocess.call(kill_cmd, shell=True)

    # catch signals to update PID state when job is killed
    # trapping SIGKILL and SIGSTOP is not possible
    signal.signal(signal.SIGHUP, handle_signal)  # in case job is killed via Yarn
    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGQUIT, handle_signal)
    # End Signal Handling block

    # setup logger
    logging.basicConfig(format='%(asctime)s %(message)s',
                        datefmt='%d/%m/%Y %H:%M:%S -',
                        level=logging.DEBUG)

    # Get product id, type and input folder
    product_dir, l1c_id, product_type = _product(input_path)

    # If the input product is a zip, unzip it to expand_dir location
    if product_type == "zip":
        # if expand_dir is given, unzip L1C.SAFE there
        if not expand_dir:
            product_dir = expand_dir
        unzip(input_path, product_dir)

    # l1c product basename and path
    l1c_basename = l1c_id + '.SAFE'
    # l2a product basename and path
    l2a_id = _l2a(l1c_id)
    l2a_basename = l2a_id + '.SAFE'
    l2a_path = os.path.join(output_dir, l2a_basename)

    # Check that output L2A folder doesn't exists already, otherwise terminate
    if os.path.isdir(l2a_path):
        logging.info("Output folder exists already {} - Terminating.".format(l2a_path))
        return

    # docker settings
    log_dir, auxdata, dem = _sen2cor_home_folders(sen2cor_home)
    volumes = _volumes(l2a_id, product_dir, output_dir, log_dir, auxdata, dem)
    if not sen2cor_image:
        sen2cor_image = "vito-docker-private.artifactory.vgt.vito.be/sen2cor:latest"
    user, uid, gid = _user_info(None, uid, gid)
    container_input = _container_folders()[0]
    docker_command = " ".join([s2c_options, os.path.join(container_input, l1c_basename)])

    # run sen2cor docker
    start_time = time.time()
    logging.info("Starting sen2cor docker process on {}".format(l1c_basename))
    container = sen2cor_docker(sen2cor_image,
                               docker_command,
                               volumes,
                               container_name,
                               uid,
                               gid,
                               use_dockerpy=use_dockerpy)
    # Log elapsed time at the end of process
    logging.info("L2A Process for {} completed in {:.0f} minutes.".format(
        l1c_id, (time.time() - start_time)/60))


def _parse_args():

    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="Input L1C product (.zip/.SAFE absolute path)")
    parser.add_argument("-o", "--output-dir", help="Output directory for L2A products")
    parser.add_argument("-s", "--sen2cor-home", help="Sen2cor home folder containing aux_data, dem, log folders")
    parser.add_argument("-e", "--expand-dir", help="Unzip location of L1C products. DEFAULT: same location of L1C zip files")
    parser.add_argument("-u", "--uid", help="User id to run the container")
    parser.add_argument("-g", "--gid", help="Group id to run the container")

    return parser.parse_known_args()


if __name__ == '__main__':

    sen2cor_image = "redblanket/sen2cor:latest"

    args, unknown_args = _parse_args()

    input_product = args.input
    output_dir = args.output_dir
    sen2cor_home = args.sen2cor_home

    s2c_options = ' '.join(unknown_args)

    expand_dir = args.expand_dir
    uid = args.uid
    gid = args.gid

    sen2cor(input_product, output_dir, sen2cor_home, sen2cor_image=sen2cor_image,
            s2c_options=s2c_options, expand_dir=expand_dir, uid=uid, gid=gid)
