#!/usr/bin/env python
# -*- coding: UTF-8 -*-
#
import os
import traceback
"""
Script to download contracts from a list of SC addresses.
Input: text file where each line is a SC address
Output:
    ./output/a6/a6e0b24c65758154cac6f33b0c455727ab6193cb_BasicTokenSC.sol
    contracts.json
"""
from pyetherchain.pyetherchain import UserAgent
import configparser
import re
import requests
import sys
from bs4 import BeautifulSoup
import traceback


class EtherScanIoApi(object):
    """
    Base EtherScan.io Api implementation
    TODO:
    - implement a script (client) that runs all the python script
    - fix the issue about SC with several classes. The issue is at 03 script
    - Fix the issue about solmet, for some address the tool is not able to get statistic at 02 and it brokes 03
    - fix _get_contract_name
    """

    def __init__(self, proxies={}):
        self.config = configparser.ConfigParser()
        self.config.read('config.ini')
        self.session = UserAgent(
            baseurl="https://etherscan.io", retry=5, retrydelay=8, proxies=proxies)
        self.soup = None

    def get_contracts_from_block(self, block):

        soup = BeautifulSoup(requests.get(
            'https://etherscan.io/txs?block=' + str(block)).text, features="html.parser")
        addresses = soup.select("i[title='Contract']")

        for address in list(set(map(lambda x: x.findNext('a')['href'].replace('/address/', ''), addresses))):
            # if not self._is_new_address(address):
            #     continue
            print(address)
            self._set_soup(address)
            self.write_etherChain_fn(address)
            # yield contract

    def write_etherChain_fn(self, address):
        with open(self.config['DEFAULT']['etherChain_fn'], 'a+') as f:
            print("got contract: %s" % address)

            f_path = os.path.join(
                self.config['DEFAULT']['output_path'], '%s.sol' % (address))
            try:
                source = self.soup.find(id="editor").text
                abi = self.soup.find(id="js-copytextarea2").text
                byteCode = self.soup.find(id="verifiedbytecode2").text
                with open(f_path, "wb") as f:
                    f.write(bytes(source + '\n' + abi + '\n' + byteCode, "utf8"))
            except:
                print(traceback.format_exc())

    def _is_new_address(self, address):
        if (address not in open(self.config['DEFAULT']['smec_fn']).read()):
            return True
        return False

    def _set_soup(self, address):
        url = address.join(['https://etherscan.io/address/', '#code'])
        self.soup = BeautifulSoup(requests.get(url).text, 'html.parser')


if __name__ == "__main__":
    e = EtherScanIoApi()
    e.get_contracts_from_block(6000003)
