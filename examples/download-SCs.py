#!/usr/bin/env python
# -*- coding: UTF-8 -*-
#
import os
"""
Script to download contracts from a list of SC addresses.
Input: text file where each line is a SC address
Output: 
    ./output/a6/a6e0b24c65758154cac6f33b0c455727ab6193cb_BasicTokenSC.sol
    contracts.json
"""
from pyetherchain.pyetherchain import UserAgent
from pyetherchain.pyetherchain import EtherChain
import configparser
import re
import requests
import sys
from bs4 import BeautifulSoup


class EtherScanIoApi(object):
    """
    Base EtherScan.io Api implementation
    TODO: 
    - fix _get_contract_name
    """

    def __init__(self, proxies={}):
        self.config = configparser.ConfigParser()
        self.config.read('config.ini')
        self.session = UserAgent(
            baseurl="https://etherscan.io", retry=5, retrydelay=8, proxies=proxies)
        self.ec = EtherChain()
        self.soup = None

    def get_contracts_from_hardcode_fn(self):
        # It gets ethereum contract addresses from a hard coding file
        for address in self._get_hardcode_addresses_from_fn():
            address = '0x' + address
            if not self._is_new_address(address):
                continue
            describe_contract = self.ec.account(address).describe_contract
            self._set_soup(address)
            contract = {'address': address,
                        'name': self._get_contract_name(),
                        'compiler': None,
                        'compiler_version': self._get_compiler_version(),
                        'balance': describe_contract.__self__['balance'],
                        'txcount': describe_contract.__self__['txreceived'],
                        'firstseen': describe_contract.__self__['firstseen'],
                        'lastseen': describe_contract.__self__['lastseen']
                        }
            yield contract

    def get_contracts_from_etherscan(self, start=0, end=None):
        page = start

        while not end or page <= end:
            resp = self.session.get("/contractsVerified/%d" % page).text
            page, lastpage = re.findall(
                r'Page <.*>(\d+)</.*> of <.*>(\d+)</.*>', resp)[0]
            page, lastpage = int(page), int(lastpage)
            if not end:
                end = lastpage
            rows = self._parse_tbodies(resp)[0]  # only use first tbody
            for col in rows:
                address = self._extract_text_from_html(col[0]).split(" ", 1)[0]
                if not self._is_new_address(address):
                    continue
                describe_contract = self.ec.account(address).describe_contract
                firstseen = describe_contract.__self__['firstseen']
                lastseen = describe_contract.__self__['lastseen']
                contract = {'address': address,
                            'name': self._extract_text_from_html(col[1]),
                            'compiler': self._extract_text_from_html(col[2]),
                            'compiler_version': self._extract_text_from_html(col[3]),
                            'balance': self._get_balance(self._extract_text_from_html(col[4])),
                            'txcount': self._extract_text_from_html(col[5]),
                            'firstseen': firstseen,
                            'lastseen': firstseen
                            }
                yield contract
            page += 1

    def write_etherChain_fn(self, contracts=[]):
        amount = 2
        for nr, c in enumerate(contracts):
            with open(self.config['DEFAULT']['etherChain_fn'], 'a') as f:
                print("got contract: %s" % c)

                f_path = os.path.join(
                    self.config['DEFAULT']['output_path'], '%s.sol' % (c["address"]))
                try:
                    source = self._get_contract_source(c["address"]).strip()
                    if not len(source):
                        raise Exception(c)
                except Exception as e:
                    continue

                f.write("%s\n" % c)
                with open(f_path, "wb") as f:
                    f.write(bytes(source, "utf8"))

                print("[%d/%d] dumped --> %s (%-20s) -> %s" %
                      (nr, amount, c["address"], c["name"], f_path))

                nr += 1
                if nr >= amount:
                    break

    def _get_contract_source(self, address):
        import time
        e = None
        for _ in range(5):
            resp = self.session.get("/address/%s" % address).text
            print("/address/%s" % address)
            if "You have reached your maximum request limit for this resource. Please try again later" in resp:
                print("[[THROTTELING]]")
                time.sleep(1+2.5*_)
                continue
            try:
                print("=======================================================")
                print(address)
                resp = resp.split(
                    "<pre class='js-sourcecopyarea editor' id='editor' style='margin-top: 5px;'>", 1)[1]
                resp = resp.split("</pre><br>", 1)[0]
                return resp.replace("&lt;", "<").replace("&gt;", ">").replace("&le;", "<=").replace("&ge;", ">=").replace("&amp;", "&").replace("&vert;", "|")
            except Exception as e:
                print('Exception: ', e)
                time.sleep(1 + 2.5 * _)
                continue
        raise e

    def _is_new_address(self, address):
        if address in open(self.config['DEFAULT']['etherChain_fn']).read():
            return False
        return True

    def _set_soup(self, address):
        url = address.join(['https://etherscan.io/address/', '#code'])
        self.soup = BeautifulSoup(requests.get(url).text, 'html.parser')

    def _get_compiler_version(self):
        try:
            str = self.soup.findAll('td', text=re.compile('v0.'))[
                0].contents[0]
            return re.search('v(\d{1,2}.\d{1,2}.\d{1,2})', str)[1]
        except IndexError:
            return None

    def _get_contract_name(self):
        try:
            return self.soup.find(lambda tag: tag.name == "span" and "Name" in tag.text).parent.find_next('td').contents[0].strip()
        except AttributeError:
            return None

    def _get_hardcode_addresses_from_fn(self):
        try:
            fp = open(self.config['DEFAULT']['hardcode_addresses_fn'])
            return list(filter(None,
                               map(lambda x: x.strip(),
                                   fp.readlines())
                               ))
        finally:
            fp.close()

    def _extract_text_from_html(self, s):
        return re.sub('<[^<]+?>', '', s).strip()

    def _extract_hexstr_from_html_attrib(self, s):
        return ''.join(re.findall(r".+/([^']+)'", s)) if ">" in s and "</" in s else s

    def _get_balance(self, balance):
        try:
            return int(re.sub('[a-zA-Z]', '', balance))
        except ValueError:
            return None

    def _get_pageable_data(self, path, start=0, length=10):
        params = {
            "start": start,
            "length": length,
        }
        resp = self.session.get(path, params=params).json()
        # cleanup HTML from response
        for item in resp['data']:
            keys = item.keys()
            for san_k in set(keys).intersection(set(("account", "blocknumber", "type", "direction"))):
                item[san_k] = self._extract_text_from_html(item[san_k])
            for san_k in set(keys).intersection(("parenthash", "from", "to", "address")):
                item[san_k] = self._extract_hexstr_from_html_attrib(
                    item[san_k])
        return resp

    def _parse_tbodies(self, data):
        tbodies = []
        for tbody in re.findall(r"<tbody.*?>(.+?)</tbody>", data, re.DOTALL):
            rows = []
            for tr in re.findall(r"<tr.*?>(.+?)</tr>", tbody):
                rows.append(re.findall(r"<td.*?>(.+?)</td>", tr))
            tbodies.append(rows)
        return tbodies


if __name__ == "__main__":
    e = EtherScanIoApi()
    e.write_etherChain_fn(e.get_contracts_from_hardcode_fn())
    # print(e.get_contracts_from_hardcode_fn())
    # e.write_etherChain_fn(e.get_contracts_from_etherscan())
