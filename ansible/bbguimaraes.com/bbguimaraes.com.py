#!/bin/env python3
import argparse
import collections
import http.client
import json
import os
import subprocess
import sys
import time
import typing
import urllib.error
import urllib.request

DOTFILES_DIR = os.path.join(os.environ['HOME'], 'src', 'dotfiles')
ANSIBLE_DIR = os.path.join(DOTFILES_DIR, 'ansible')
REGION = 'fra1'
VOLUME_NAME_FMT = '{}-vol'
VOLUME_DEV_FMT = '/dev/disk/by-id/scsi-0DO_Volume_{}'
VOLUME_SIZE_GB = 50
DROPLET_SIZE = 's-2vcpu-4gb'
DROPLET_IMAGE = 'centos-8-x64'
DROPLET_SSH_KEY = 23710396

CmdRetType = typing.Optional[int]
CmdFnType = typing.Callable[[argparse.Namespace], CmdRetType]

def main(argv: typing.List[str]) -> CmdRetType:
    args = parse_args(argv)
    args.verbose = log if args.verbose else (lambda *_: None)
    cmd: CmdFnType = args.cmd
    return cmd(args)

def parse_args(argv: typing.List[str]) -> argparse.Namespace:
    token_arg = lambda p: p.add_argument(
        '--digital-ocean-token',
        type=read_only_file_arg, metavar='path', required=True)
    parser = argparse.ArgumentParser()
    parser.add_argument('-v', '--verbose', action='store_true')
    sub = parser.add_subparsers(dest='cmd', required=True)
    droplets_parser = sub.add_parser('droplets')
    droplets_parser.set_defaults(cmd=cmd_droplets)
    droplets_parser.add_argument('--raw', action='store_true')
    token_arg(droplets_parser)
    new_parser = sub.add_parser('new')
    new_parser.set_defaults(cmd=cmd_new)
    new_parser.add_argument('--dry-run', action='store_true')
    new_parser.add_argument('name', type=str)
    token_arg(new_parser)
    return parser.parse_args(argv)

def log(*args, **kwargs):
    print(*args, **kwargs, file=sys.stderr)

def read_only_file_arg(filename: str) -> str:
    with open(filename) as f:
        return f.read()

class DigitalOcean(object):
    def __init__(self, args: argparse.Namespace):
        self._verbose = args.verbose
        self._dry_run = getattr(args, 'dry_run', False)
        self.token = args.digital_ocean_token.rstrip()
        self._verbose('Using DigitalOcean token:', self.token)

    def _request(
        self, method: str, url: str,
        headers: typing.Optional[typing.Dict]=None,
        data: typing.Optional[bytes]=None,
    ) -> typing.Optional[http.client.HTTPResponse]:
        headers = headers or {}
        headers['Authorization'] = f'Bearer {self.token}'
        url = f'https://api.digitalocean.com/v2/{url}'
        self._verbose(f'Request: {method} {url}')
        if data:
            self._verbose(f'Data: {data.decode("utf-8")}')
        try:
            ret = urllib.request.urlopen(
                urllib.request.Request(
                    url=url, method=method, headers=headers, data=data))
        except urllib.error.HTTPError as ex:
            print(f'{ex}, response:', file=sys.stderr)
            print(ex.read().decode('utf-8'), end='')
            raise
        self._verbose(f'Response: {ret.status}')
        if ret.status >= 400:
            print(f'Response status {ret.status}, contents:')
            print(ret.read().decode('utf-8'))
            return None
        return ret

    def _post_json(self, url: str,
        headers: typing.Optional[typing.Dict]=None,
        j: typing.Dict[str, typing.Any]=None
    ) -> typing.Optional[http.client.HTTPResponse]:
        headers = headers = {}
        headers['Content-Type'] = 'application/json'
        return self._request(
            'POST', url, headers, json.dumps(j).encode('utf-8'))

    def get_volumes(self):
        return json.load(self._request('GET', 'volumes'))['volumes']

    def get_droplets(self):
        return json.load(self._request('GET', 'droplets'))['droplets']

    def create_volume(self, name: str) -> typing.Optional[str]:
        self._verbose('Creating volume', name)
        if self._dry_run:
            return None
        resp = self._post_json('volumes', j={
            'name': name,
            'region': REGION,
            'size_gigabytes': VOLUME_SIZE_GB,
        })
        if resp:
            return json.load(resp)['volume']['id']
        return None

    def create_droplet(self, name: str) -> typing.Optional[dict]:
        self._verbose('Creating droplet', name)
        if self._dry_run:
            return None
        resp = self._post_json('droplets', j={
            'name': name,
            'region': REGION,
            'size': DROPLET_SIZE,
            'image': DROPLET_IMAGE,
            'ssh_keys': [DROPLET_SSH_KEY],
            'backups': False,
        })
        if not resp:
            return None
        return json.load(resp)['droplet']

    def wait_for_droplet(self, id: int) -> bool:
        self._verbose('Waiting for droplet', repr(id))
        i = 10
        url = f'droplets/{id}'
        while True:
            resp = self._request('GET', url)
            if not resp:
                return False
            status = json.load(resp)['droplet']['status']
            if status == 'active':
                return True
            self._verbose(f'Sleeping for {i}s, current status: {status}')
            time.sleep(i)

    def attach_volume(
        self, vol_id: str, vol: str, droplet_id: int
    ) -> typing.Optional[str]:
        self._verbose('Attaching volume', vol, 'to droplet', droplet_id)
        if self._dry_run:
            return 'action_id'
        resp = self._post_json(f'volumes/{vol_id}/actions', j={
            'type': 'attach',
            'volume_name': vol,
            'droplet_id': droplet_id,
            'region': REGION,
        })
        if resp:
            return json.load(resp)['action']['id']
        return None

    def wait_for_action(self, id: str):
        self._verbose('Waiting for action', repr(id))
        if self._dry_run:
            return True
        i = 10
        url = f'actions/{id}'
        while True:
            resp = self._request('GET', url)
            if not resp:
                return False
            status = json.load(resp)['action']['status']
            if status == 'completed':
                return True
            if status == 'errored':
                print('Action', repr(id), 'errored')
                return False
            self._verbose(f'Sleeping for {i}s, current status: {status}')
            time.sleep(i)

class Ansible(object):
    def __init__(self, args: argparse.Namespace, host):
        self._verbose = args.verbose
        self._dry_run = args.dry_run
        self._host = host

    def __enter__(self):
        self._inventory = tempfile.NamedTemporaryFile()
        self._inventory.write(f'''\
{self._host}

[servers]
{self._host}

[bbguimaraes_com]
{self._host}
'''.encode('utf-8'))
        self._inventory.flush()
        return self

    def __exit__(self, *_):
        self._inventory.close()

    def playbook(
        self, playbook: str,
        args: typing.Sequence[str]=(),
        params: typing.Optional[typing.Dict[str, str]]=None,
        root: bool=False,
        become: bool=False,
    ):
        cmd = [
            'ansible-playbook', os.path.join(ANSIBLE_DIR, playbook),
            '--inventory', self._inventory.name,
            '--limit', self._host,
            *args,
        ]
        if root:
            cmd.append('-u')
            cmd.append('root')
        if become:
            cmd.append('--become')
        if params:
            for x in params.items():
                cmd.append('-e')
                cmd.append('='.join(x))
        self._verbose('Executing Ansible playbook:', cmd)
        if self._dry_run:
            return
        subprocess.check_call(cmd)

def cmd_droplets(args: argparse.Namespace) -> CmdRetType:
    l = DigitalOcean(args).get_droplets()
    if args.raw:
        json.dump(l, sys.stdout)
        return None
    for d in l:
        id, name = d['id'], d['name']
        print(f'{id}: {name}')
    return None

def cmd_new(args: argparse.Namespace) -> CmdRetType:
    name = args.name
    vol = VOLUME_NAME_FMT.format(name)
    do = DigitalOcean(args)
    vol_id = new_create_volume(args, do, vol)
    if not vol_id:
        return 1
    droplet = new_create_droplet(args, do, name)
    if not droplet:
        return 1
    if not do.wait_for_droplet(droplet['id']):
        return 1
    if vol_id not in droplet['volume_ids']:
        action_id = do.attach_volume(vol_id, vol, droplet['id'])
        if not (action_id and do.wait_for_action(action_id)):
            return 1
    address = next(
        x for x in droplet['networks']['v4']
        if x['type'] == 'public'
    )['ip_address']
    with Ansible(args, address) as ansible:
        ansible.playbook('bbguimaraes.com/base.yaml', root=True)
        ansible.playbook('base/base.yaml', root=True, params={
            'sudo_wheel_nopasswd': 'true',
        })
        ansible.playbook('swap.yaml', become=True)
        ansible.playbook('base/base_user.yaml')
        ansible.playbook('bbguimaraes.com/volume.yaml', become=True, params={
            'volume_format_disk': 'true',
            'volume_dev': VOLUME_DEV_FMT.format(vol),
            'volume_dir': f'/mnt/{vol}',
        })
        ansible.playbook('bbguimaraes.com/podman.yaml', become=True)
        return None

def new_create_volume(
    args: argparse.Namespace, do: DigitalOcean, name: str
) -> typing.Optional[str]:
    args.verbose('Checking if volume', name, 'exists')
    l = do.get_volumes()
    if v := next((x for x in l if x['name'] == name), None):
        return v['id']
    return do.create_volume(name)

def new_create_droplet(
    args: argparse.Namespace, do: DigitalOcean, name: str
) -> typing.Optional[dict]:
    args.verbose('Checking if droplet', name, 'exists')
    l = do.get_droplets()
    if d := next((x for x in l if x['name'] == name), None):
        return d
    return do.create_droplet(name)

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
