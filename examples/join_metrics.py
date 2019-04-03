import ast
import configparser
import glob
import os
import re
import subprocess


class MergeMetrics(object):
    '''
    Base Metrics Api implementation
    '''

    def __init__(self):
        self.config = configparser.ConfigParser()
        self.config.read('config.ini')
        self.smec_fn = self.config['DEFAULT']['smec_fn']
        self.overview_metrics = False

    def _get_addresses(self):
        '''
        get the addresses which are in contracts_overview_file but not in smec_fn
        '''
        return list(
            set(self._get_addresses_from_contracts_overview()) - set(self._get_addresses_from_smec_fn()))

    def _get_addresses_from_contracts_overview(self):
        # TODO you should get all the information in order to join them with solmet metrics
        # you can store it in self.overview_metrics
        with open(self.config['DEFAULT']['contracts_overview_file'], 'r') as f:
            return [ast.literal_eval(line)['address'] for line in f]

    def _get_addresses_from_smec_fn(self):
        with open(self.smec_fn, 'r') as f:
            addresses = [row.split(';')[0] for row in f][1:]
            return [re.search('[a-zA-Z0-9]{40}', address).group(0) for address in addresses]
        return ['0xf2e88e0bfe61e5e41d9317e82c6938e67a913cc1', '0xf67fbf1c2df2da7f96c7ffee9151eff7246d7922', '0xe9bb29e794e18fcfce5eb81510b878c34d729172', '0xcf3c3d59414b3dd856cfa2fb3a7f86d5656d9b3b', '0xc5b177940534c2e03eb7d9e624ed25cdc8a97739', '0x56325d180ec3878a9028afc7b0edcee7486cc9df', '0xaec1f783b29aab2727d7c374aa55483fe299fefa', '0xe8856D0EaDeb8a11b3B6C0d552214078CeF8B328']

    def _get_metrics_from_solmet_fn(self, address):
        return os.path.join(
            self.config['DEFAULT']['output_path'], '.'.join([address, 'out']))

    def _get_metrics_from_etherChain(self):
        with open(self.config['DEFAULT']['contracts_overview_file'], 'r') as f:
            return [ast.literal_eval(line) for line in f]

    def join_etherscan_solmet(self):
        for address in self._get_addresses():
            try:
                lines = open(self._get_metrics_from_solmet_fn(
                    address), 'r').readlines()
            except (TypeError, FileNotFoundError) as e:
                print(e)
                continue
            try:
                print('obj: ', lines[1].rstrip())
                # TODO you need to join the information stored into self.overview_metrics
                # self.outf.write(';'.join([
                #     lines[1].rstrip(),
                #     obj['firstseen'],
                #     obj['lastseen'],
                #     obj['compiler_version'], '\n'
                # ]))
            except IndexError:
                print("fn: ", fn)
        # self.outf.close()


if __name__ == "__main__":
    m = MergeMetrics()
    # print(m._get_addresses())
    print(m._get_metrics_from_etherChain())
    # m.join_etherscan_solmet()
    # print(m._get_sol_file_name({'address': '0x79a64dbe0a25390fa40a2eb819b934ccc7a06f45', 'name': 'ALLDigitalToken', 'compiler': 'Solidity', 'compiler_version': '0.4.25', 'balance': 0, 'txcount': '1', 'firstse    en': '2019-02-26T05:04:06.000Z', 'lastseen': '2019-02-26T05:04:06.000Z'}))
