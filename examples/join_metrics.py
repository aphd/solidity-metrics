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

        self.metrics_from_etherChain = self._get_metrics_from_etherChain()

    def _get_addresses(self):
        '''
        get the addresses which are in contracts_overview_file but not in smec_fn
        '''
        return list(
            set(self._get_addresses_from_etherChain_fn()) - set(self._get_addresses_from_smec_fn()))

    def _get_addresses_from_etherChain_fn(self):
        return list(self.metrics_from_etherChain.keys())

    def _get_addresses_from_smec_fn(self):
        with open(self.smec_fn, 'r') as f:
            addresses = [row.split(';')[0] for row in f][1:]
            return [re.search('[a-zA-Z0-9]{40}', address).group(0) for address in addresses]

    def _get_metrics_from_solmet_fn(self, address):
        return os.path.join(
            self.config['DEFAULT']['output_path'], '.'.join([address, 'out']))

    def _get_metrics_from_etherChain(self):
        with open(self.config['DEFAULT']['etherChain_fn'], 'r') as f:
            return {ast.literal_eval(line)['address']: ast.literal_eval(line) for line in f}

    def join_etherscan_solmet(self):
        for address in self._get_addresses():
            try:
                lines = open(self._get_metrics_from_solmet_fn(
                    address), 'r').readlines()
            except (TypeError, FileNotFoundError) as e:
                print(e)
                continue
            try:
                print('solmet: ', lines[1].rstrip())
                print('etherChain:', self.metrics_from_etherChain[address])
                obj = self.metrics_from_etherChain[address]
                self.smec_fn.write(';'.join([
                    lines[1].rstrip(),
                    obj['firstseen'],
                    obj['lastseen'],
                    obj['compiler_version'], '\n'
                ]))
            except IndexError as e:
                print("IndexError: ", e)
        self.smec_fn.close()


if __name__ == "__main__":
    m = MergeMetrics()
    print(m.join_etherscan_solmet())
    # m.join_etherscan_solmet()
    # print(m._get_sol_file_name({'address': '0x79a64dbe0a25390fa40a2eb819b934ccc7a06f45', 'name': 'ALLDigitalToken', 'compiler': 'Solidity', 'compiler_version': '0.4.25', 'balance': 0, 'txcount': '1', 'firstse    en': '2019-02-26T05:04:06.000Z', 'lastseen': '2019-02-26T05:04:06.000Z'}))
