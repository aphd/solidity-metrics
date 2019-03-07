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
import re, requests
from bs4 import BeautifulSoup

class EtherScanIoApi(object):
    """
    Base EtherScan.io Api implementation
    """

    def __init__(self, proxies={}):
        self.session = UserAgent(
            baseurl="https://etherscan.io", retry=5, retrydelay=8, proxies=proxies)
        self.ec = EtherChain()
        self.soup = None

    def get_contracts(self):

        for address in self._get_sc_addresses_from_file():
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

    def get_contract_source(self, address):
        import time
        e = None
        for _ in range(20):
            resp = self.session.get("/address/%s" % address).text
            if "You have reached your maximum request limit for this resource. Please try again later" in resp:
                print("[[THROTTELING]]")
                time.sleep(1+2.5*_)
                continue
            try:
                print("=======================================================")
                print(address)
                resp = resp.split(
                    "</div><pre class='js-sourcecopyarea' id='editor' style='margin-top: 5px;'>", 1)[1]
                resp = resp.split("</pre><br>", 1)[0]
                return resp.replace("&lt;", "<").replace("&gt;", ">").replace("&le;", "<=").replace("&ge;", ">=").replace("&amp;", "&").replace("&vert;", "|")
            except Exception as e:
                print(e)
                time.sleep(1 + 2.5 * _)
                continue
        raise e

    def _set_soup(self, address):
        url = address.join(['https://etherscan.io/address/','#code'])
        self.soup = BeautifulSoup(requests.get(url).text, 'html.parser')        

    def _get_compiler_version(self):
        str = self.soup.findAll('td', text = re.compile('v0.'))[0].contents[0]
        return re.search('v(\d{1,2}.\d{1,2}.\d{1,2})', str)[1]

    def _get_contract_name(self):
        return soup.find(lambda tag:tag.name=="span" and "Name" in tag.text).parent.find_next('td').contents[0].strip()

    def _get_sc_addresses_from_file(self, fn = '/tmp/add.out'):
        try:  
            fp = open(fn)
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
    
    def _get_page_content(self, url):
        return BeautifulSoup( urllib2.urlopen(url).read() )

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
    #print(list(e.get_contracts()))

    output_directory = "./output"
    overwrite = False
    amount = 100

    e = EtherScanIoApi()
    for nr, c in enumerate(e.get_contracts()):
        with open("contracts.json", 'a') as f:
            print("got contract: %s" % c)
            dst = os.path.join(output_directory, c["address"].replace(
                "0x", "")[:2].lower())  # index by 1st byte
            if not os.path.isdir(dst):
                os.makedirs(dst)
            fpath = os.path.join(dst, "%s_%s.sol" % (
                c["address"].replace("0x", ""), str(c['name']).replace("\\", "_").replace("/", "_")))
            if not overwrite and os.path.exists(fpath):
                print(
                    "[%d/%d] skipping, already exists --> %s (%-20s) -> %s" % (nr, amount, c["address"], c["name"], fpath))
                continue

            try:
                source = e.get_contract_source(c["address"]).strip()
                if not len(source):
                    raise Exception(c)
            except Exception as e:
                continue

            f.write("%s\n" % c)
            with open(fpath, "wb") as f:
                f.write(bytes(source, "utf8"))

            print("[%d/%d] dumped --> %s (%-20s) -> %s" %
                (nr, amount, c["address"], c["name"], fpath))

            nr += 1
            if nr >= amount:
                print(
                    "[%d/%d] finished. maximum amount of contracts to download reached." % (nr, amount))
                break
