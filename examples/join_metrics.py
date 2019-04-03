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
        self.smec_h = open(self.smec_fn, 'a')

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
                obj = self.metrics_from_etherChain[address]
                self.smec_h.write(';'.join([
                    lines[1].rstrip(),
                    obj['firstseen'],
                    obj['lastseen'],
                    str(obj['compiler_version']), '\n'
                ]))
            except IndexError as e:
                print("IndexError: ", e)
        self.smec_h.close()


if __name__ == "__main__":
    m = MergeMetrics()
    m.join_etherscan_solmet()
